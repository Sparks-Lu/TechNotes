# TTS（Text-to-Speech）模型技术调研报告

> 调研时间：2026-11-12
> 筛选条件：免费可商用 · 支持中英文 · 支持多角色 · GPU 服务器可部署

---

## 方案速查对比表

### 推荐模型（2025-2026 最新）

| 排名 | 模型 | 发布 | 参数量 | 许可证 | 商用限制 | VRAM 需求 | 语言支持 | 多角色 |
|------|------|------|--------|--------|----------|-----------|----------|--------|
| 1 | **Qwen3-TTS** | 2026 | 0.6B / 1.7B | Apache-2.0 | ✅ 无限制 | 4-8GB | 10种语言 | 9预设+克隆 |
| 2 | **CosyVoice 2** | 2025 | 0.5B | Apache-2.0 | ✅ 无限制 | ~6-8GB | 中英日韩+方言 | 声音克隆 |
| 3 | **Kokoro 82M** | 2025 | 82M | Apache-2.0 | ✅ 无限制 | <2GB | 8种语言 | 54种音色 |
| 4 | **IndexTTS 2.5** | 2026 | 0.8B | bilibili License | ⚠️ 有限商用 | ~4-6GB | 中英日西阿 | 声音克隆+情感 |
| 5 | **VibeVoice** | 2026 | 1.5B / 7B | MIT | ⚠️ 不推荐商用 | 6-20GB | 中英双语 | 最多4角色 |
| 6 | **MeloTTS** | 2024 | - | MIT | ✅ 无限制 | CPU可运行 | 6种语言 | 10+音色 |

### 其他值得关注的模型

| 模型 | 发布 | 不满足推荐原因 | 备注 |
|------|------|----------------|------|
| **Fish Speech / S2 Pro** | 2025-2026 | 商用需付费许可 | 质量优秀，80+语言 |
| **ChatTTS** | 2024 | 模型不可商用 (CC BY-NC 4.0) | 中英双语，多角色 |
| **Dia 1.6B** | 2025 | 仅支持英文 | 对话生成能力强 |
| **MaskGCT** | 2024 | 许可证不明确 | 跨语言声音克隆 |

---

## 一、领域概述

TTS（Text-to-Speech，文本转语音）技术是将文本转换为自然语音的技术。2024-2026 年间，基于大语言模型（LLM）和扩散模型的 TTS 技术取得重大突破，从早期的单一音色合成发展到如今的多角色对话、零样本声音克隆、跨语言生成等能力。

**2025-2026 年重要进展**：
- **Qwen3-TTS**（阿里巴巴，2026 年）支持 10 种语言，9 个预设音色，3 秒声音克隆，Apache-2.0 完全开源
- **CosyVoice 2**（阿里巴巴，2025 年）实现 150ms 超低延迟流式合成，支持中英日韩及中国方言
- **Kokoro 82M**（2025 年）以 82M 超轻量参数实现 54 种音色，VRAM 需求 <2GB
- **VibeVoice**（微软，2026 年）支持最长 90 分钟多角色对话合成
- **IndexTTS 2.5**（B站，2026 年）0.8B 参数，支持中英日西阿 5 语言，情感与音色解耦控制，语速控制，发音控制（拼音/CMU音素/日语假名），bilibili 自定义许可证

本报告聚焦于**可免费商用**、支持**中英文**、支持**多角色**且可在 **GPU 服务器**上部署的开源模型。

---

## 二、核心评估维度

### 1. 许可证与商用自由度

TTS 模型的许可证体系复杂，主要分为以下几类：

| 许可证类型 | 商用自由度 | 代表模型 |
|-----------|-----------|----------|
| **Apache-2.0** | ✅ 完全自由，无需注册，无收入上限 | Qwen3-TTS, CosyVoice 2, Kokoro 82M |
| **MIT** | ✅ 完全自由，但部分模型有使用建议 | VibeVoice, MeloTTS |
| **bilibili Model License** | ⚠️ 有限商用：MAU>1亿或年收入>10亿需单独授权；不可用于改进其他AI模型 | IndexTTS 2.5 |
| **Fish Audio Community License** | ⚠️ 商用需付费协议 | Fish Speech, Fish Audio S2 Pro |
| **CC BY-NC 4.0** | ❌ 不可商用 | ChatTTS（模型部分） |

### 2. 显存需求与 GPU 服务器兼容性

GPU 服务器通常配备 NVIDIA Tesla T4（16GB）、A10（24GB）、A100（40/80GB）等显卡。

| 模型规模 | FP16 全精度 | 量化后 | GPU 兼容性 |
|---------|------------|--------|-----------|
| 82M（Kokoro） | <1GB | - | ✅ 任意 GPU / CPU |
| 0.5-0.6B（CosyVoice 2, Qwen3-TTS-0.6B） | ~4-6GB | ~4GB | ✅ Tesla T4 可批量部署 |
| 1.5-1.7B（VibeVoice, Qwen3-TTS-1.7B） | ~6-8GB | ~6GB | ✅ Tesla T4 兼容 |
| 7B（VibeVoice Large） | ~20GB | ~12GB(Q8) / ~8GB(Q4) | ✅ A10/A100 推荐 |

### 3. 多角色与声音克隆能力

| 能力类型 | 说明 | 代表模型 |
|---------|------|----------|
| **预设音色** | 内置多个固定音色 | Kokoro（54种）、Qwen3-TTS（9种） |
| **零样本克隆** | 3-30秒参考音频克隆任意声音 | Qwen3-TTS、CosyVoice 2、IndexTTS 2.5 |
| **多角色对话** | 单次生成多角色对话音频 | VibeVoice（最多4角色）、Dia（通过标签） |
| **跨语言克隆** | 用一种语言的声音说另一种语言 | Qwen3-TTS、CosyVoice 2 |

---

## 三、推荐模型详解

### 1. Qwen3-TTS — 2026 年综合最优选 🏆

**来源**：阿里巴巴通义团队（2026 年发布）

**核心架构**：
- 提供 **0.6B** 和 **1.7B** 两种参数规模
- 基于 LLM 的文本到语音模型
- 支持 Voice Design（通过自然语言描述生成新音色）

**许可证**：Apache-2.0（完全开源商用，无限制）

**语言支持**：
- 10 种语言：中文、英文、日语、韩语、德语、法语、俄语、葡萄牙语、西班牙语、意大利语
- 支持多种方言和口音

**多角色能力**：
- **9 个预设音色**（不同年龄、性别、方言）
- **3 秒声音克隆**：仅需 3 秒参考音频即可克隆任意声音
- **跨语言克隆**：用中文声音说英文
- **Voice Design**：通过文字描述生成全新音色

**VRAM 需求**：
- 0.6B 版本：约 4GB
- 1.7B 版本：约 6-8GB
- 支持 FlashAttention 2 降低显存占用
- Tesla T4：✅ 完全兼容

**质量表现**：
- 首包延迟仅 97ms
- 超高质量类人语音生成
- 在多项评测中优于同规模模型

**适用场景**：多语言应用、声音克隆服务、虚拟助手、有声书、多角色对话

**开源地址**：
- GitHub: https://github.com/QwenLM/Qwen3-TTS
- HuggingFace: Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice

---

### 2. CosyVoice 2 — 流式合成与方言支持

**来源**：阿里巴巴通义实验室（2025 年发布）

**核心架构**：
- **0.5B 参数**
- 流式语音合成架构
- 语义-声学两阶段生成

**许可证**：Apache-2.0（完全开源商用，无限制）

**语言支持**：
- 中文（含粤语、四川话、上海话、天津话等方言）
- 英文、日文、韩文
- 支持中英混合

**多角色能力**：
- 零样本声音克隆（3秒参考音频）
- 跨语言克隆
- 多风格控制

**VRAM 需求**：
- 约 6-8GB（FP16）
- Tesla T4：✅ 兼容

**质量表现**：
- **150ms 超低延迟**（流式合成）
- 发音错误率较前代降低 30%-50%
- MOS 分数从 5.4 提升到 5.53

**适用场景**：实时对话系统、方言应用、低延迟场景、多语言客服

**开源地址**：
- GitHub: https://github.com/FunAudioLLM/CosyVoice
- HuggingFace: FunAudioLLM/CosyVoice2-0.5B

---

### 3. Kokoro 82M — 超轻量级首选

**来源**：hexgrad（2025 年发布）

**核心架构**：
- **仅 82M 参数**（极轻量）
- 高效蒸馏模型

**许可证**：Apache-2.0（完全开源商用，无限制）

**语言支持**：
- 8 种语言（包括中文、英文）

**多角色能力**：
- **54 种预设音色**（数量最多）
- 按语言和风格分类

**VRAM 需求**：
- 权重仅约 1GB
- 推理时约 <2GB VRAM
- 支持 CPU 推理（约 4GB RAM）
- Tesla T4：✅ 可批量部署多实例

**质量表现**：
- 质量媲美大模型
- 在 82M 参数量级达到 SOTA

**适用场景**：资源受限环境、边缘部署、批量并发服务、快速原型

**开源地址**：
- GitHub: https://github.com/hexgrad/kokoro
- HuggingFace: hexgrad/Kokoro-82M

---

### 4. IndexTTS 2.5 — 情感与发音精细控制

**来源**：哔哩哔哩（B站）Index Team（2026 年 8 月发布）

**核心架构**：
- **0.8B 参数**
- 自回归零样本 TTS 模型
- 情感与音色解耦设计
- 支持 vLLM 生产部署

**许可证**：bilibili Model Use License Agreement（自定义许可证）
- ⚠️ **商用限制**：
  - 月活 > 1 亿或年收入 > 10 亿人民币需单独授权
  - 不可用于改进其他 AI 模型（IndexTTS 自身衍生品或非商业 AI 模型除外）
  - 需保留版权声明和许可证文本

**语言支持**：
- 中文、英文、日语、西班牙语、阿拉伯语（5 种语言）
- 支持跨语言声音克隆

**多角色能力**：
- 零样本声音克隆（单音频参考）
- **情感与音色独立控制**：可分别调整音色和情感风格
- **情感控制方式多样**：
  - 情感参考音频（`emo_audio_prompt`）
  - 8 维情感向量 `[happy, angry, sad, afraid, disgusted, melancholic, surprised, calm]`
  - 文本自动情感推断（`use_emo_text`）
  - 情感强度调节（`emo_alpha`，0.0-1.0）
- **语速控制**：`duration_factor`（0.5x-2.0x）
- **发音控制**：
  - 中文拼音标注
  - 英文 CMU 音素标注
  - 日语假名标注

**VRAM 需求**：
- 约 4-6GB（BF16 推理）
- 支持 FP16/FP32/BF16 精度
- 支持 DeepSpeed 加速（效果因硬件而异）
- Tesla T4：✅ 兼容

**质量表现**：
- **Benchmark（CV3-Eval 零样本 TTS）**：
  | 指标 | 中文 | 英文 | 日文 | 西班牙文 | 阿拉伯文 | 平均 |
  |------|------|------|------|----------|----------|------|
  | WER↓ | 4.36 | 5.12 | 5.66 | 3.75 | 14.88 | 6.75 |
  | SS↑ | 77.10 | 68.06 | 74.62 | 76.39 | 69.74 | 73.18 |
- **IndexTTS2.5-RL**（强化学习版）平均 WER 降至 6.00，SS 提升至 73.63
- **推理速度**（RTF，RTX 4090）：BF16 约 0.21，比 IndexTTS 2 快约 36%

**适用场景**：需要精细情感控制的应用、有声书、游戏配音、虚拟角色、多语言内容

**开源地址**：
- GitHub: https://github.com/index-tts/index-tts
- HuggingFace: https://huggingface.co/IndexTeam/IndexTTS-2.5
- ModelScope: https://modelscope.cn/models/IndexTeam/IndexTTS-2.5
- vLLM 部署: https://recipes.vllm.ai/IndexTeam/IndexTTS-2.5

---

### 5. VibeVoice — 长对话多角色合成

**来源**：Microsoft（2026 年发布）

**核心架构**：
- **1.5B** 和 **7B** 两种版本
- 专为多角色对话设计

**许可证**：MIT（代码开源，但官方不推荐商用）

**语言支持**：
- 英文、中文（双语原生支持）

**多角色能力**：
- **最多 4 个不同角色**单次合成
- 长达 **90 分钟**连续对话生成
- 角色间音色区分度高

**VRAM 需求**：
- 1.5B 版本：约 6-8GB
- 7B 版本：约 20GB（FP16）/ 12GB（Q8）/ 8GB（Q4）
- Tesla T4：1.5B ✅，7B 需量化

**质量表现**：
- 大模型质量更优
- 小模型偶尔出现"幻觉背景音乐"问题

**适用场景**：播客生成、有声剧、多角色对话、长音频内容

**注意**：虽然 MIT 许可证允许商用，但官方明确表示"不推荐在商业环境中使用"，建议仅用于研究。

**开源地址**：
- GitHub: https://github.com/microsoft/VibeVoice

---

### 6. MeloTTS — CPU 可运行的轻量方案

**来源**：MyShell AI（2024 年发布）

**核心架构**：
- 轻量级多语言 TTS
- 针对不同语言有独立模型

**许可证**：MIT（完全开源商用，无限制）

**语言支持**：
- 英文、西班牙文、法文、中文、日文、韩文
- **支持中英混合输入**

**多角色能力**：
- 10+ 种预设音色（按语言和地区区分）
- 美式英文、英式英文、澳洲英文等

**VRAM 需求**：
- **CPU 实时推理**，无需 GPU
- GPU 加速可选

**质量表现**：
- Hugging Face 下载量最高的 TTS 模型之一
- 质量稳定，适合生产环境

**适用场景**：无 GPU 环境、边缘设备、多语言基础应用、快速部署

**开源地址**：
- GitHub: https://github.com/myshell-ai/MeloTTS

---

## 四、其他值得关注的模型

### Fish Speech / Fish Audio S2 Pro

**特点**：
- Fish Speech：13种语言，CC BY-NC-SA 4.0（不可商用）
- Fish Audio S2 Pro：80+语言，Fish Audio Research License（商用需付费）
- 35B 参数（Drama 3 版本），质量优秀
- 10-30秒声音克隆

**不满足推荐原因**：商用需要付费许可

---

### ChatTTS

**特点**：
- 支持中英文
- 多角色对话能力
- 代码：AGPLv3+
- 模型：CC BY-NC 4.0（不可商用）

**不满足推荐原因**：模型部分不可商用

---

### Dia 1.6B

**特点**：
- 1.6B 参数
- Apache 2.0 许可证
- 通过 [S1] [S2] 标签实现多角色对话
- VRAM：4.4-7.9GB

**不满足推荐原因**：仅支持英文，不支持中文

---

### MaskGCT

**特点**：
- 零样本声音克隆
- 支持中英文及多语言
- 跨语言生成
- Amphion 工具包的一部分

**不满足推荐原因**：许可证不明确

---

## 五、Benchmark 数据汇总

### 定量指标对比

| 模型 | 参数量 | 首包延迟 | MOS 评分 | 语言数 | 音色数 | WER↓ (中/英) | SS↑ (中/英) |
|------|--------|---------|---------|--------|--------|--------------|-------------|
| **Qwen3-TTS** | 0.6B/1.7B | 97ms | - | 10 | 9+克隆 | 3.27 / 5.06 | 73.02 / 67.17 |
| **CosyVoice 2** | 0.5B | 150ms | 5.53 | 4+方言 | 克隆 | - | - |
| **Kokoro** | 82M | - | - | 8 | 54 | - | - |
| **IndexTTS 2.5** | 0.8B | - | - | 5 | 克隆 | 4.36 / 5.12 | 77.10 / 68.06 |
| **IndexTTS 2.5-RL** | 0.8B | - | - | 5 | 克隆 | 3.93 / 3.89 | 77.92 / 67.79 |
| **VibeVoice** | 1.5B/7B | - | - | 2 | 4角色 | - | - |
| **MeloTTS** | - | - | - | 6 | 10+ | - | - |

### GPU 服务器部署推荐

| 场景 | 推荐模型 | GPU 配置 | 并发能力 |
|------|----------|----------|----------|
| **高并发轻量服务** | Kokoro 82M | Tesla T4 | 单卡 10+ 并发 |
| **多语言高质量** | Qwen3-TTS 1.7B | Tesla T4 / A10 | 单卡 4-8 并发 |
| **方言应用** | CosyVoice 2 | Tesla T4 | 单卡 4-6 并发 |
| **情感精细控制** | IndexTTS 2.5 | Tesla T4 / A10 | 单卡 4-6 并发 |
| **长对话/播客** | VibeVoice 1.5B | Tesla T4 / A10 | 单卡 2-4 并发 |
| **无 GPU 环境** | MeloTTS | CPU | 取决于 CPU 核心 |
| **生产级部署** | IndexTTS 2.5 + vLLM | A10 / A100 | 高吞吐 |

---

## 六、许可证安全等级

### ✅ 安全商用（Apache-2.0，无限制）

| 模型 | 发布年份 | 备注 |
|------|---------|------|
| **Qwen3-TTS** | 2026 | 完全自由，可修改/分发/商用 |
| **CosyVoice 2** | 2025 | 完全自由 |
| **Kokoro 82M** | 2025 | 完全自由 |

### ⚠️ 有限商用（自定义许可证，需关注限制条件）

| 模型 | 许可证 | 条件 |
|------|--------|------|
| **IndexTTS 2.5** | bilibili Model License | MAU>1亿或年收入>10亿需单独授权；不可用于改进其他AI模型 |
| **VibeVoice** | MIT | 许可证允许，但官方不推荐商用 |

### ❌ 不可商用

| 模型 | 许可证 | 备注 |
|------|--------|------|
| **Fish Speech** | CC BY-NC-SA 4.0 | 非商用 |
| **Fish Audio S2 Pro** | Fish Audio Research License | 商用需付费 |
| **ChatTTS** | CC BY-NC 4.0（模型） | 模型不可商用 |

---

## 七、技术趋势（2025-2026）

| 趋势 | 说明 |
|------|------|
| **LLM-based TTS** | 基于大语言模型的 TTS 成为主流，质量大幅提升 |
| **零样本声音克隆** | 3-30秒参考音频即可克隆任意声音，无需微调 |
| **多语言统一** | 单模型支持 10+ 种语言，跨语言克隆成为标配 |
| **超低延迟** | 流式合成首包延迟降至 100-150ms，实时对话成为可能 |
| **轻量化部署** | 82M 参数模型质量媲美大模型，<2GB VRAM 可运行 |
| **情感控制** | 情感与音色解耦，支持细粒度情感调节 |
| **长音频生成** | 单次生成长达 90 分钟的连续对话音频 |

---

## 八、商用推荐与选型指南

### 按场景推荐

| 应用场景 | 推荐模型 | 理由 |
|----------|----------|------|
| **综合最优** | **Qwen3-TTS** | 10语言、9音色、3秒克隆、Apache-2.0 |
| **资源受限/高并发** | **Kokoro 82M** | <2GB VRAM、54音色、单卡高并发 |
| **方言应用** | **CosyVoice 2** | 支持中英日韩+方言、150ms低延迟 |
| **情感精细控制** | **IndexTTS 2.5** | 情感与音色独立控制、发音标注、vLLM 部署 |
| **长对话/播客** | **VibeVoice** | 最多4角色、90分钟连续生成 |
| **无GPU环境** | **MeloTTS** | CPU实时推理、6语言 |

### 按企业规模推荐

| 企业类型 | 推荐模型 | 理由 |
|----------|----------|------|
| **初创/中小企业** | **Qwen3-TTS** / **Kokoro** | Apache-2.0 无限制，成本最优 |
| **大型企业** | **Qwen3-TTS 1.7B** | 质量最优，多语言支持 |
| **个人开发者** | **Kokoro 82M** | 轻量易部署，CPU可运行 |

### 综合推荐（Top 4）

1. **Qwen3-TTS** — 2026 年综合最优选，10语言、9音色、3秒克隆、Apache-2.0 完全开源
2. **Kokoro 82M** — 超轻量首选，<2GB VRAM、54音色、单卡可高并发部署
3. **CosyVoice 2** — 方言与低延迟场景最优，150ms流式合成、中英日韩+方言
4. **IndexTTS 2.5** — 情感与发音控制最强，8维情感向量、拼音/音素标注、vLLM 部署（注意：bilibili 许可证，大企业需单独授权）

---

## 九、总结

2025-2026 年 TTS 领域迎来重大突破。**Qwen3-TTS**（阿里巴巴）以 10 种语言、9 个预设音色、3 秒声音克隆能力成为综合最优选；**Kokoro 82M** 以超轻量参数实现 54 种音色，VRAM 需求 <2GB；**CosyVoice 2** 实现 150ms 超低延迟流式合成，支持中国方言；**IndexTTS 2.5**（哔哩哔哩）在情感与发音精细控制方面表现突出，支持 8 维情感向量与拼音/音素标注。

**Qwen3-TTS、Kokoro、CosyVoice 2** 均采用 **Apache-2.0** 许可证，可在 GPU 服务器上免费商用部署。**IndexTTS 2.5** 采用 bilibili 自定义许可证，MAU>1亿或年收入>10亿的企业需单独授权，且不可用于改进其他 AI 模型。

Tesla T4（16GB）可运行所有推荐模型，其中 Kokoro 82M 可支持高并发场景，Qwen3-TTS 1.7B 可提供最优质量。

**选型建议**：
- 追求综合最优：Qwen3-TTS
- 追求高并发/轻量：Kokoro 82M
- 需要方言支持：CosyVoice 2
- 需要情感/发音控制：IndexTTS 2.5（注意许可证限制）
- 长对话/播客：VibeVoice（注意商用限制）

---

## 参考链接

- Qwen3-TTS: https://github.com/QwenLM/Qwen3-TTS
- Qwen3-TTS 博客: https://qwen.ai/blog?id=qwen3tts-0115
- CosyVoice 2: https://github.com/FunAudioLLM/CosyVoice
- CosyVoice 2 论文: https://arxiv.org/html/2412.10117v2
- Kokoro TTS: https://github.com/hexgrad/kokoro
- Kokoro HuggingFace: https://huggingface.co/hexgrad/Kokoro-82M
- IndexTTS: https://github.com/index-tts/index-tts
- IndexTTS 2.5 论文: https://arxiv.org/abs/2601.03888
- IndexTTS 2.5 HuggingFace: https://huggingface.co/IndexTeam/IndexTTS-2.5
- IndexTTS 2.5 ModelScope: https://modelscope.cn/models/IndexTeam/IndexTTS-2.5
- IndexTTS 2.5 vLLM 部署: https://recipes.vllm.ai/IndexTeam/IndexTTS-2.5
- VibeVoice: https://github.com/microsoft/VibeVoice
- MeloTTS: https://github.com/myshell-ai/MeloTTS
- Fish Speech: https://github.com/fishaudio/fish-speech
- Dia TTS: https://github.com/nari-labs/dia
- MaskGCT: https://github.com/open-mmlab/Amphion
- BentoML TTS 指南: https://www.bentoml.com/blog/exploring-the-world-of-open-source-text-to-speech-models
- Modal TTS 指南: https://modal.com/blog/open-source-tts
- Cartesia 许可证对比: https://www.cartesia.ai/learn/open-source-tts
