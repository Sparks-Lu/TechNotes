# idol-sdk（Idol：单张图 → 3D Gaussian Splat）代码与合规评审

> 评审对象：https://github.com/speridlabs/idol-sdk （commit `8db7003`，main 分支）
> 评审时间：2026-11-19
> 评审方式：clone 源码逐文件阅读（`idol/` 共 1,639 行 + `demo/` 258 行）；GitHub/ModelScope-HF Mirror API 核对元数据与许可证；官方 README、项目页、模型卡交叉比对。
> **未做**：没有 GPU，未实机跑通推理，未复现官方 benchmark。因此本文对"效果"只给可信度判断，不给质量结论。
> 一句话结论：**工程质量高于一般研究代码，值得拿来做原型；但"Apache-2.0 = 可商用"这个说法不成立，且性能与体积的公开数字与自己给的代码对不上。**

---

## 目录

- [0. 结论速览](#0-结论速览)
- [1. 项目快照](#1-项目快照)
- [2. 它是什么：技术栈与数据流](#2-它是什么技术栈与数据流)
- [3. 核心风险：许可证链路（P1）](#3-核心风险许可证链路p1)
- [4. 代码质量：值得肯定的部分](#4-代码质量值得肯定的部分)
- [5. 问题清单（按严重度）](#5-问题清单按严重度)
  - [5.1 P1：质量证据不可验证](#51-p1质量证据不可验证)
  - [5.2 P2：文档数字与代码/数据自相矛盾](#52-p2文档数字与代码数据自相矛盾)
  - [5.3 P2：AMD/ROCm 实际不可用](#53-p2amdrocm-实际不可用)
  - [5.4 P3：健壮性与可复现性细节](#54-p3健壮性与可复现性细节)
- [6. 对我们业务的适配判断](#6-对我们业务的适配判断)
- [7. 上线前的三道门槛](#7-上线前的三道门槛)
- [8. 诚实边界](#8-诚实边界)
- [附录 A：证据与复核命令](#附录-a证据与复核命令)
- [附录 B：术语](#附录-b术语)

---

## 0. 结论速览

1. **定位清晰**：物体级"单图 → 3DGS"，输入一张照片/渲染图，输出标准 3DGS `.ply`（含图片没拍到的侧面）。它不做房间/全景重建，与"全景图→三维模型"是互补而非替代。
2. **代码是真的干净**：单一职责模块、safetensors + `strict=True`、无 pickle/eval/subprocess、gated 权限下载前预检、PLY 写盘处理了 inf 与坐标系转换。这类细节一般研究仓库会漏。
3. **最大的坑是许可证链路**：仓库 Apache-2.0，但默认 `config.json` 强制依赖 **Meta DINOv3 ViT-H+/16（gated，自定义许可）** 与 **black-forest-labs/FLUX.2-dev（非商用许可）**。官方的规避办法（换成 Apache-2.0 的 FLUX.2-klein-4B 的 VAE）能解掉 FLUX，**解不掉 DINOv3**。
4. **公开数字自相矛盾**：README 说"under 2 seconds"，自己的 GPU 表最快是 3.4 s（B300）、4090 是 19.1 s；项目页说 32,768/262,144/1,048,576 高斯对应 0.4/3.2/12.2 MB，而代码写出的 PLY 实测应有约 2.2/17.8/71.3 MB（17 个 float32 属性 × 68 B/点）。
5. **工程化配套缺失**：0 测试、0 CI、0 release/tag、0 评测脚本、issue 无人回复；PR 中 AMD 支持与"约束几何修正"两个都被关闭未合并。
6. **建议**：内部评估/原型可直接用（先跑 license 规避配置）；对外产品化前必须完成第 7 节的三道门槛。

---

## 1. 项目快照

| 项 | 值 | 口径 |
|---|---|---|
| 发布方 | Sperid Labs（org `speridlabs`，12 个仓库，iris-3b 233★、eneas 88★） | GitHub API |
| 创建 / 最近 push | 2026-10-28 / 2026-11-09 | GitHub API |
| Star / Fork / Watch | 1,165 / 116 / 10 | GitHub API |
| Open issues | 3（#14 HF integration、#12 ROCm cuDNN、#6 AMD 计时报告），**均无维护者回复** | GitHub API |
| 提交数 / release / tag | 5 次提交 / 0 个 release / 无版本 tag | git log、GitHub API |
| 外部贡献者 | 5 人（各 1 次提交），PR：#9/#7/#5/#3 已合并，#10/#8 关闭未合并 | git、GitHub API |
| 代码规模 | `idol/` 1,639 行 + `demo/app.py` 234 行 + `demo/model.py` 24 行 | wc -l |
| 目录 | `LICENSE` `README.md` `idol/` `idol/models/` `demo/` `assets/gallery/` `pyproject.toml` `.gitignore`；**无 tests/、无 .github/、无 NOTICE、无 py.typed** | 文件清单 |
| 版本 | 0.1.0（`__init__.py`、`pyproject.toml` 一致） | 源码 |
| 权重 | HF `speridlabs/idol`：4 个 safetensors + config.json，约 3 GB，`license: apache-2.0` | HF API |
| 托管入口 | HF Space（Gradio，ZeroGPU）+ fal 商业 endpoint（项目页提到 "Partnered with fal to push Idol v1 to Idol Max"） | README、项目页 |

---

## 2. 它是什么：技术栈与数据流

```
一张图（照片 / 渲染图 / Iris-3B 生成图）
  → BiRefNet 去背景（220.7M，FP16）
  → alpha 腐蚀 1px → 按 bbox × crop_margin 裁方图（synthetic 1.2 / real 1.7）→ 1024²，黑底合成
  → 条件编码：DINOv3 ViT-H+/16（840.6M，bf16，layer_norm 后的 token）
             + FLUX.2 VAE（84.1M，bf16，patchified latent token，前置 5 个 padding）
  → LatentSeqMMFlowModel（370.6M DiT，8192 object token + 1 camera token 联合注意力）
  → Euler 50 步 rectified-flow 采样，CFG 3.0，time shift 3.0（系统重采样八叉树放置 anchors）
  → GaussianFixedlenDecoder（237.3M）：每个 anchor 出 32 个高斯
  → 输出：.ply（标准 3DGS）+ _input.png + _camera.json（yaw/pitch/radius/fov）
```

关键事实（来自源码与 `config.json`）：

- 生成核心 0.66B（370.6M DiT + 50.8M 八叉树解码器 + 237.3M 高斯解码器）；整条请求含辅助模型约 1.80B。
- 权重 3.7–4.4 GB，**峰值 7.2 GB**，因此 10 GB 卡（3080）能跑，只是慢（46.2 s）。
- 物体坐标约定：z-up、落在 `[-0.5, 0.5]³`；写 PLY 时统一转成 y-up 并同步旋转四元数。
- 只写 degree-0 球谐（`f_dc_0..2`），**无视角相关高光**——金属、玻璃、清透材质会偏"平"。
- 高斯数是运行时参数（32,768–1,048,576，32 的倍数），同一模型可出"粗模"或"终稿"，这是它设计上最实用的一点。

---

## 3. 核心风险：许可证链路（P1）

`idol-sdk` 仓库与 `speridlabs/idol` 权重都是 Apache-2.0，但**跑起来必须有 2 个第三方 gated 模型**，默认配置里写死：

```json
"image_encoders": {
  "dinov3": "facebook/dinov3-vith16plus-pretrain-lvd1689m",
  "flux2_vae": "black-forest-labs/FLUX.2-dev"
}
```

| 组件 | 仓库 | 许可证（HF tag 实测） | 是否 gated | 商用判定 |
|---|---|---|---|---|
| Idol 代码 + 权重 | `speridlabs/idol-sdk` / `speridlabs/idol` | Apache-2.0 | 否 | ✅ 可商用（含专利授权、需保留声明） |
| 图像编码器 | `facebook/dinov3-vith16plus-pretrain-lvd1689m` | `other`（Meta DINOv3 License） | **manual gated** | ⚠️ 允许商用但带条件：分发模型/衍生件必须附协议全文、发表需声明 DINO Materials、禁止出口管制受限用途（军事/核/间谍/武器）、禁止逆向、不可转让、Meta 可单方改协议 |
| VAE | `black-forest-labs/FLUX.2-dev` | `other`（FLUX.2-dev Non-Commercial License） | 是 | ❌ 非商用；商用需向 BFL 购买授权 |
| VAE 替代 | `black-forest-labs/FLUX.2-klein-4B` | **apache-2.0**，且 `vae/` 子目录齐全 | 否 | ✅ 这是官方在 README 里明示的规避路径 |
| 去背景 | BiRefNet（vendored 进 `idol/models/birefnet.py`，491 行） | 上游 MIT | 否 | ✅ 但**本仓库未附带上游版权与许可声明** |

要点：

1. **"Apache-2.0 模型"是片面的宣传**。链路里真正的闸门是 DINOv3：它比 FLUX 更麻烦，因为它是 gated（要人工审批）且分发条件严格。如果我们的产品把 Idol 生成的资产（而非模型）交付客户，DINOv3 的再分发条款一般不构成阻碍，但"内部推理服务"与"打包交付模型"要分开评估。
2. **官方已经给了 FLUX 的解法**，而且写进 README：`image_encoders={"flux2_vae": "/models/FLUX.2-klein-4B"}`，并且"只有 repo id 才会做 gated 检查"，所以本地目录可离线加载。这条设计是加分项，说明作者知道自己在绕过什么。
3. **声明文件缺失**：`dit.py` 顶部完整保留了 Wan/HuggingFace 的 Apache-2.0 头（做法正确），但 `birefnet.py` 没有任何上游声明，README 只在 Acknowledgements 里提了一句 BiRefNet/TripoSplat。MIT/Apache 都要求分发时附带许可文本 → 需要补 `THIRD_PARTY_NOTICES`。
4. **fal 商业 endpoint 不等于许可证解决**：走托管 API 可以不用自己下载 gated 权重，但这只把"运行"外包了，模型侧条款与内容合规责任仍在你的合同里。

---

## 4. 代码质量：值得肯定的部分

- **写盘正确性**（`idol/gaussian.py:40-50`）：`inverse_sigmoid` 前对 opacity 做 `clamp(eps, 1-eps)`、scale 取 log 前 `clamp_min(eps)`，避免饱和值写成 ±inf 被部分查看器拒收；z-up→y-up 同时旋转位置和四元数（`quaternion_multiply` 用 (w,x,y,z) Hamilton 积），坐标系处理是教科书级的。
- **下载前的权限预检**（`idol/conditioning.py:18-52`）：在拉 ~3 GB 权重之前先 `auth_check`，区分"未登录"与"未获批"给不同指引；网络异常**不**当作无权限（因为可能已命中本地缓存）；`HF_HUB_OFFLINE` 直接跳过。这是踩过坑的人才会写的逻辑。
- **数值/精度的克制**（`idol/pipeline.py:36-87`）：只对 DiT 的 transformer block 做 `torch.compile`（解码器保持 eager），编译产物按类缓存并绑定到实例；TF32 与 cuDNN attention 用 `contextmanager` 进出成对恢复，不污染全局；cuDNN 只在 sm80+ 开启（#9 修的就是 T4/sm75 上会失败的问题）。
- **采样实现干净**（`idol/sampler.py`）：Euler + time shift 的显式写法，`batch_cfg` 把 guided/unguided 合成 batch=2 一次前向，公式与非 batch 路径一致，可读可比。
- **八叉树放置**（`idol/models/decoder.py:44-115`）：systematic resampling，含零和行的均匀回退、按 unique count 分组减少重复计算——比多数开源实现细致。
- **CLI/SDK 分层**：`python -m idol.sample` 与 `IdolPipeline` 一一对应；`--weights` 支持本地目录；`IDOL_DEVICE` 环境变量；`ATTN_BACKEND` 可强制 flash_attn/sdpa；每个产物（ply / _input.png / _camera.json）都有解释用途。
- **demo 成熟**：`demo/model.py` 在 import 期加载权重、ZeroGPU 下关闭 `torch.compile`（因为 ZeroGPU 不支持）；`demo/app.py` 有 preset JSON、随机示例排序后索引回映射、viewer zoom 因子注释说明为什么是 5.5/3。这不是"论文附录级"的 demo。

总体：可读性、注释密度、错误信息质量都明显高于同类研究仓库；作者把"能跑起来"当产品在做。

---

## 5. 问题清单（按严重度）

| 级别 | 问题 | 证据 | 影响 | 建议动作 |
|---|---|---|---|---|
| **P1** | 许可证链路（DINOv3 gated + FLUX.2-dev 非商用 + vendored BiRefNet 无声明） | `config.json`、HF license tag、`idol/models/birefnet.py` 无头注释 | 商用判定错误风险；分发合规风险 | 走 klein VAE；写 DINOv3 条款评估；补 `THIRD_PARTY_NOTICES` |
| **P1** | 质量证据不可验证 | 仓库无 eval 脚本、无测试集说明、无失败案例展示 | 无法判断在"我们的脏数据"上表现 | 自建 30–50 张样本评测（见第 7 节） |
| **P2** | 速度宣传与自己表格矛盾 | README："under 2 seconds"；表格：B300 3.4 s / H100 6.7 s / 4090 19.1 s / 3080 46.2 s | 选型与 SLA 误判 | 以 GPU 表格为准，实测自己的卡 |
| **P2** | 文件体积宣传与代码矛盾 | 项目页 0.4 / 3.2 / 12.2 MB；按 `save_ply` 的 17 个 float32 属性计算应为 ≈2.2 / 17.8 / 71.3 MB | 存储、CDN、加载时长估算会低估 4–6 倍 | 按"未压缩 PLY"预算；或自行转 SPZ/splat 压缩 |
| **P2** | AMD/ROCm 实际不可用 | `pipeline.py:84` 用 `get_device_capability()>=8` 判定，ROCm 下会误判为支持；#12 未回复、#10 AMD PR 关闭未合并 | 国产化/AMD 算力池不可规划 | 需求含 AMD 则先别押注 |
| **P3** | `decode_camera` 未防御负的 `inverse_distance` | `camera.py:15-17` | 异常时 radius 为负，下游相机解释错乱 | 加 `max(inverse_distance, eps)` 或显式报错 |
| **P3** | alpha 判定过宽 | `preprocess.py:9-10`：只要有 1 个非 255 像素就认定"有真 alpha"，跳过 BiRefNet | 半透明 PNG/遮罩残留图会跳过抠图，结果不可控 | 改为按不透明比例阈值判定 |
| **P3** | 裁剪坐标 int 截断 | `preprocess.py:33` 用 `int(center±half)` | 贴近边缘时物体中心偏移约半像素级、非对称 | 用 round 并对齐奇偶 |
| **P3** | "同 seed 同结果"仅同设备成立 | `pipeline.py:129` 只设 `torch.manual_seed`；TF32/cuDNN/compile 路径改变数值 | 跨机型复现差异、回归测试假阳性 | 文档写明；评测固定硬件与 `--no_optimize` |
| **P3** | 依赖只设下界不设上界 | `pyproject.toml`：`transformers>=4.56`（代码用 `dtype=`）、`diffusers>=0.40`（用 `AutoencoderKLFlux2`） | 上游升级即可能崩（#7 就是修 `torch_dtype` 弃用） | 锁版本区间 + 冒烟测试 |
| **P3** | SDK 无安全/内容检查 | fal endpoint schema 有 `enable_safety_checker`，SDK 侧没有 | 产品化需自建内容过滤与水印 | 在产品层补齐 |
| **P3** | SDK 与托管 API 输出不对等 | fal 返回 `model_glb`（点云预览），SDK 只写 `.ply` | 引擎对接需自行转 GLB | 加 ply→glb 导出或文档说明 |
| **P3** | 工程配套缺失 | 无 tests / CI / py.typed / CONTRIBUTING / SECURITY / CHANGELOG / release；`.gitignore` 里有 `.ruff_cache` 但仓库无 ruff 配置 | 升级与二次开发无护栏 | 自己 fork 加 CI |

### 5.1 P1：质量证据不可验证

README 与项目页给的对比表（Idol / TripoSplat / TRELLIS / LGM，输入视角 PSNR·SSIM·LPIPS·IoU，7 个新视角 DINOv2·CLIP·sharpness distance）有四个缺口：测试集名称与规模未给；没有可运行的评测脚本；对比对象的"Setting"不统一（LGM 用 65,536 高斯、TRELLIS 用论文设置 50+50 步）；对 LGM 更高的 PSNR 用"PSNR 对平方误差取平均所以模糊也高分"一句话解释掉，却没有给 perceptual 之外的证据。结论：**"8 列里赢 6 列"目前只能当厂商数字。**

### 5.2 P2：文档数字与代码/数据自相矛盾

PLY 体积按代码可直接推算：`save_ply` 写 17 个属性（x,y,z / nx,ny,nz / f_dc_0..2 / opacity / scale_0..2 / rot_0..3），每个 `f4` = 4 字节 → **68 字节/点**（不含头）。

| 高斯数 | 按代码应有 | 项目页宣称 | 比值 |
|---|---|---|---|
| 32,768 | ≈2.2 MB | 0.4 MB | 5.5× |
| 262,144 | ≈17.8 MB | 3.2 MB | 5.6× |
| 1,048,576 | ≈71.3 MB | 12.2 MB | 5.8× |

约 5.5–5.8× 的一致性比值说明：那组 MB 数字很可能来自**压缩/编码后的产物**（例如 .splat/SPZ 或 gzip），而不是 SDK 默认写出的"standard 3DGS .ply"。文档没说明，就把容量规划带偏。速度同理：正文"under 2 seconds"在自家表格里找不到对应行（最快 3.4 s）。

### 5.3 P2：AMD/ROCm 实际不可用

`self.cudnn_attention = self.optimize and torch.cuda.get_device_capability(...)[0] >= 8` 这个门是 CUDA 语义。ROCm 下 `torch.cuda` 映射到 HIP，capability 会返回按 GCN 架构换算的数字（普遍 ≥8），于是仍会选 `SDPBackend.CUDNN_ATTENTION`，在 AMD 上失败或退化。#6 是用户提交的 RX 7800 XT 计时报告、#12 明确要求"ROCm 跳过 cuDNN"、#10 的 AMD 支持 PR 被关闭未合并——仓库对 AMD 的立场实际上是"不支持"。

### 5.4 P3：健壮性与可复现性细节

见上表最后 8 行。另外两点值得记录：`--device cpu` 能选，但解码器权重被 `convert_module_to_f16` 转成 fp16，CPU 上 fp16 矩阵乘很慢且部分算子可能回退，实际不可用；MPS 路径官方标注约 18 分钟/262,144 高斯（M4 MacBook Air），能验证但不是生产力。

---

## 6. 对我们业务的适配判断

- **能力定位**：物体级 image→3DGS。适合展品、道具、商品、单件家具这类"一张图想让它转起来"的需求；不适合空间/房间（那是全景→3D 那条路线，见 `CV/pano/全景图生成三维模型_技术与产品调研_20261118.md`）。两者可拼：**空间用全景重建，物体用 Idol**，比用同一套模型硬吃两个任务更稳。
- **交付形态注意**：输出是点云状高斯、无视角相关反射，`[-0.5,0.5]³` 的归一化尺寸意味着**没有真实尺度**，做展陈/电商展示可以，做"可测量"不行。
- **硬件现实**：峰值 7.2 GB，T4（16 GB，sm75）能装下但拿不到 cuDNN 快路径，预期接近 3080 的量级（≈45 s 级），不要按"2 秒"排产；一张 T4 顶多撑 2–3 并发。4090 约 19 s，H100 约 7 s。
- **与 3D 版产品的关系**：我们此前把"三维重建"定位为调用外部能力（今鱼视觉平台 API）而不是自研。Idol 这类物体级生成可以作为**独立供给**（图片资产→3D 展品）接入，接入时先解决 DINOv3/FLUX 的许可与 gated 审批（审批要提前申请，可能等几天），否则会在上线节点被卡。
- **不建议押注的点**：AMD 显卡池、CPU 推理、需要真实尺度/精确几何的展陈工程图。

---

## 7. 上线前的三道门槛

1. **自有数据评测（1 周）**
   - 样本：30–50 张，覆盖我们的真实分布——棚拍展品、手机随手拍、渲染图、带反光/透明、细长结构（支架、线缆）、多物体干扰。
   - 指标：输入视角 PSNR/SSIM/LPIPS + 人眼"转一圈"评分（背面是否可信、是否有漂浮碎片、接缝）；体积/首屏加载时间（按代码算的真实 PLY 大小，别按宣传数字）。
   - 固定变量：同一 GPU、`--no_optimize` 与 optimize 各跑一遍，记录差异。
2. **许可与依赖收口（并行）**
   - VAE 一律走 `FLUX.2-klein-4B`；提交 DINOv3 gated 申请（预留审批时间）。
   - 建立 `THIRD_PARTY_NOTICES`（Apache/MIT/DINOv3/FLUX 各自条款 + BiRefNet 上游声明）。
   - 锁依赖区间（transformers/diffusers/torch），产出"离线镜像"（本地权重目录 + `HF_HUB_OFFLINE`），既避审批抖动也便于内网部署。
3. **工程护栏（1–2 周）**
   - 冒烟测试：1 张固定图 + 固定 seed → 断言高斯数、PLY 字节区间、若干视角 PSNR 阈值。
   - 导出链：ply → SPZ/压缩 splat → GLB 点云/mesh（补上 SDK 缺的 GLB 输出）。
   - 内容安全：自建 NSFW/IP 过滤（SDK 无 safety checker），加 AI 生成标识。

---

## 8. 诚实边界

1. **没有实机运行**：本评审基于源码阅读 + 官方文档 + API 元数据；未跑通推理，未验证 7.2 GB 峰值、未验证效果。所有性能数字都来自官方自报。
2. **许可证判定为合规提示而非法律意见**：DINOv3/FLUX 条款会更新，"能否商用"的最终判断需法务按当时协议文本确认；尤其"只交付生成资产、不分发模型"这一常见情形需要单独确认。
3. **`FLUX.2-klein-4B` 的 VAE 与 `FLUX.2-dev` 是否逐权重相同**：官方 README 声称"any FLUX.2 repo with the same autoencoder in `vae/`"，我核对了 klein-4B 仓库确有 `vae/` 且许可证为 Apache-2.0，但**未逐张量比对**，也未验证换 VAE 后生成质量是否变化——这会影响条件特征，必须实测。
4. **体积/速度矛盾的判断基于代码算式**：我用 `save_ply` 的属性表（17×float32）推算字节数，未生成真实文件校验；不排除官方文档指的是 Space/网页端的压缩产物。
5. **issue 无人回复仅代表截至 2026-11-19 的公开记录**，不代表私下不支持；社区另有第三方 ComfyUI 节点（`Nynxz/ComfyUI-Idol`）可作对照，但我未审查其代码与安全。
6. **项目很新**（发布 3 周），本文件里的结论有效期短，建议 1 个月内复查 license tag、commit 活动与 issue 响应。

---

## 附录 A：证据与复核命令

```bash
# 仓库元数据 / issue / PR
curl -s https://api.github.com/repos/speridlabs/idol-sdk
curl -s https://api.github.com/repos/speridlabs/idol-sdk/issues?state=open
curl -s https://api.github.com/repos/speridlabs/idol-sdk/pulls?state=closed

# 许可证实测（HF 直连不通时用 hf-mirror 同路径）
curl -s https://hf-mirror.com/speridlabs/idol/raw/main/config.json
curl -s https://hf-mirror.com/api/models/facebook/dinov3-vith16plus-pretrain-lvd1689m   # license=other, gated=manual
curl -s https://hf-mirror.com/api/models/black-forest-labs/FLUX.2-dev                     # license=other
curl -s https://hf-mirror.com/api/models/black-forest-labs/FLUX.2-klein-4B                # license=apache-2.0, 含 vae/*

# 代码结构
git clone https://github.com/speridlabs/idol-sdk && cd idol-sdk
wc -l idol/*.py idol/models/*.py          # 合计 1,639 行
python -m py_compile idol/*.py idol/models/*.py demo/*.py   # 语法通过
grep -rnE "pickle|torch\.load|eval\(|exec\(|subprocess" --include=*.py .   # 仅 nn.Module.eval()，无风险调用

# PLY 体积推算（对应第 5.2 节）
# 17 个 float32 属性 = 68 B/点 → 32,768≈2.2MB / 262,144≈17.8MB / 1,048,576≈71.3MB
```

**关键源码位置**

| 位置 | 内容 |
|---|---|
| `idol/pipeline.py:36-46` | `compile_for_sampling`：按类编译 forward 并绑定实例，解码器保持 eager |
| `idol/pipeline.py:77-86` | birefnet 在 cuda/mps 下 `.half()`；`cudnn_attention` 仅 sm80+（AMD 误判点） |
| `idol/conditioning.py:18-52` | gated 预检 + 离线豁免 + 分场景指引 |
| `idol/gaussian.py:36-58` | PLY 写出：inf 钳制 + z-up→y-up + 四元数旋转 |
| `idol/preprocess.py:6,13-37` | `CROP_MARGIN = {'synthetic':1.2,'real':1.7}`；alpha 判定与裁剪 |
| `idol/camera.py:12-18` | 相机解码（负 `inverse_distance` 未防御） |
| `idol/models/dit.py:1-14` | 保留 Wan/HuggingFace Apache-2.0 头（正例） |
| `idol/models/birefnet.py` | vendored BiRefNet 491 行，无上游声明（反例） |
| `pyproject.toml:8-21` | 依赖只设下界；`demo` extra 锁 `gradio==5.49.1` |

## 附录 B：术语

| 术语 | 含义 |
|---|---|
| **3DGS** | 3D Gaussian Splatting，用大量三维高斯椭球表示场景/物体 |
| **DiT** | Diffusion/Diffusion-Transformer 主干；此处为 rectified-flow DiT |
| **rectified flow** | 把噪声到数据的路径拉成直线的生成框架，采样步数需求少 |
| **CFG** | Classifier-Free Guidance，无分类器引导，`w=3.0` |
| **octree decoder** | 八叉树解码器，决定高斯锚点在空间中落在哪些体素 |
| **SH degree 0** | 0 阶球谐，只有基础颜色，无视角相关高光 |
| **SPZ / .splat** | 3DGS 压缩格式，体积远小于原始 PLY |
| **gated（HF）** | 需在模型页接受条款、由作者审批后才能下载权重 |

---

*文档版本：v1.0（2026-11-19）·评审基线 commit `8db7003`*
