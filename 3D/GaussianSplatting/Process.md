Performing a photorealistic 3D room reconstruction using 3D Gaussian Splatting (3DGS) relies on a robust open-source pipeline. By leveraging your smartphone camera alongside zero-cost open-source software (OSS), you can bypass expensive cloud platforms and process everything locally. [1, 2]

---

## Step 1: Smartphone Data Capture (The Gold Standard)

The accuracy of your 3D model depends completely on the quality of your source footage. You can capture individual photos, but shooting a high-resolution video and extracting frames guarantees smooth, overlapping data continuity. [3, 4, 5, 6]

1. Lock Camera Settings: Open your phone’s default pro camera app (or a manual camera app). Set White Balance to Manual and Lock Focus to an infinite or mid-room distance. If your settings drift frame-to-frame, the reconstruction software will fail. [7, 8]

2. Eliminate Motion Blur: Set your shutter speed to a minimum of 1/500s. Increase lighting by flipping on every light switch in the room. [5, 8]

3. The Three-Height Orbit: Walk slowly around the room facing slightly inward toward the center. Record a continuous video using three distinct horizontal paths:
   
   - *Pass 1 (High)*: Camera angled upwards, scanning where walls meet the ceiling.
   - *Pass 2 (Middle)*: Camera at eye level, sweeping across furniture and doorways.
   - *Pass 3 (Low)*: Camera low to the ground, angled upward to record baseboards and floor geometry. [5, 9, 10, 11]

4. Ensure Strict Overlap: Keep your movements smooth. Ensure every square inch of the room is captured from at least three different viewing angles. [9, 12]

---

## Step 2: Extract Frames via FFmpeg (OSS)

Transfer your video file to your computer. Open your terminal or command prompt and run FFmpeg to extract clean, uncompressed still images at a regular interval (e.g., aiming for roughly 200–600 sharp frames total): [2, 13, 14]

```bash
ffmpeg -i room_video.mp4 -vf "fps=4,scale=iw:ih" -qscale:v 2 frames/frame_%04d.jpg
```

---

## Step 3: Compute Camera Poses via COLMAP 4.x (OSS)

Before creating Gaussians, the machine needs to track exactly where your phone was physically positioned for every frame. [2, 4]

1. Download the latest version of COLMAP Structure-from-Motion.
2. Create a project directory containing an `/images` subfolder and paste your extracted frames inside.
3. Run Feature Extraction (relying on the integrated SIFT algorithm to pinpoint corners and textures).
- touch database.db

- colmap feature_extractor \
      --database_path ./database.db \
      --image_path ./images \
      --ImageReader.single_camera 1 \
      --SiftExtraction.use_gpu 0
4. Run Feature Matching followed by Bundle Adjustment (Reconstruction).
- colmap exhaustive_matcher \
      --database_path ./database.db \
      --SiftMatching.use_gpu 0

- mkdir -p ./sparse

- colmap mapper \
   --database_path ./database.db \
   --image_path ./images \
   --output_path ./sparse
5. Export the Scene: Choose "Export Model as Text". This generates your critical `cameras.txt`, `images.txt`, and a sparse point cloud `points3D.txt`. [4, 10, 13, 15]

---

## Step 4: Train the Model via `gsplat` or Nerfstudio (OSS)

To dynamically transform the point cloud into fuzzy, photorealistic 3D ellipsoids (splats), you need an open-source training engine. [2, 4]

The most flexible framework is [Nerfstudio](https://github.com/nerfstudio-project/gsplat), which uses the high-performance `gsplat` backend library. *(Note: Requires an NVIDIA GPU with at least 12GB VRAM)*. [1, 10, 16, 17, 18]

1. Initialize your dataset by pointing the software directly at your COLMAP directory:
   
   ```bash
   ns-process-data colmap --data ./your_room_folder --output-dir ./processed_data
   ```

2. Launch the standard 3D Gaussian Splatting trainer:
   
   ```bash
   ns-train splatfacto --data ./processed_data
   ```

3. Monitor progress in your browser via the provided interactive web-viewer URL. Once the optimization reaches 30,000 steps, export your finalized `.ply` file. [1, 2, 4, 19]

---

## Step 5: Clean Up Your Scene in SuperSplat (OSS)

Room captures often generate accidental "floaters"—stray artifacts or visual noise showing through windows or doors. [19, 20, 21]

1. Open the browser-based, open-source [SuperSplat Editor](https://superspl.at/editor).
2. Drag and drop your trained `.ply` file into the canvas.
3. Use the Polygon Selection Tool or bounding box sliders to crop away the ceiling or isolate the walls.
4. Click Export to save a tightly optimized, highly responsive `.splat` file ready to load on any mobile web viewer or game engine. [2, 4, 19, 22, 23]

---

## End-to-End Pipeline Summary

```unset
[Phone Video] ➔ [FFmpeg] ➔ [COLMAP 4.x] ➔ [Nerfstudio / gsplat] ➔ [SuperSplat] (Capture)       (Frames)     (Camera Poses)       (GPU Training)       (Crop & Clean)
```

To optimize this process for your exact machine, tell me:

- What are your computer's hardware specifications (specifically your NVIDIA GPU model and available VRAM)?
- Are you comfortable using command-line/terminal tools, or would you prefer a fully automated one-click script (like *quicksplat*) running via Docker or Linux/WSL2? [1, 10, 13, 17]

[1] [https://community.opendronemap.org](https://community.opendronemap.org/t/opensplat-open-source-gaussian-splatting/19371)

[2] [https://themenonlab.blog](https://themenonlab.blog/blog/supersplat-gaussian-splatting-3d-photos-open-source)

[3] [https://oasisyang.github.io](https://oasisyang.github.io/colmap-free-3dgs/)

[4] [https://www.splatlabs.ai](https://www.splatlabs.ai/blog/colmap-4-gaussian-splatting-reconstruction)

[5] [https://www.reddit.com](https://www.reddit.com/r/GaussianSplatting/comments/1mzyzax/interior_gaussian_splatting/)

[6] [https://www.kiriengine.app](https://www.kiriengine.app/tutorial/introduction-to-3dgs-scan)

[7] [https://rd.nytimes.com](https://rd.nytimes.com/projects/gaussian-splatting-guide/)

[8] [https://www.youtube.com](https://www.youtube.com/watch?v=PYr-LSOf2OY)

[9] [https://www.reddit.com](https://www.reddit.com/r/VisionPro/comments/1f0ea5d/tutorial_how_to_scan_your_own_gaussian_splats/)

[10] [https://www.youtube.com](https://www.youtube.com/watch?v=k_fJrKkmBdw)

[11] [https://cesium.com](https://cesium.com/learn/reality-data/reconstruction/)

[12] [https://www.youtube.com](https://www.youtube.com/watch?v=zS1AOiyljmQ&t=464)

[13] [https://www.reddit.com](https://www.reddit.com/r/GaussianSplatting/comments/1su92sf/built_an_opensource_onescript_pipeline_video_3d/)

[14] [https://towardsdatascience.com](https://towardsdatascience.com/turn-yourself-into-a-3d-gaussian-splat-3a2bc59a770f/)

[15] [https://www.youtube.com](https://www.youtube.com/watch?v=-3TBbukYN00&t=421)

[16] [https://github.com](https://github.com/nerfstudio-project/gsplat)

[17] [https://www.reddit.com](https://www.reddit.com/r/GaussianSplatting/comments/1ryqwdt/endtoend_pipeline_for_video_to_3d_gaussian/)

[18] [https://developer.nvidia.com](https://developer.nvidia.com/blog/revolutionizing-neural-reconstruction-and-rendering-in-gsplat-with-3dgut/)

[19] [https://medium.com](https://medium.com/@Jamesroha/gaussian-splatting-a-complete-student-guide-to-3d-capture-in-2026-1195a6265870)

[20] [https://www.youtube.com](https://www.youtube.com/watch?v=0lfJqzjuKEA)

[21] [https://ieeexplore.ieee.org](https://ieeexplore.ieee.org/iel8/11449931/11449932/11449992.pdf)

[22] [https://www.reddit.com](https://www.reddit.com/r/GaussianSplatting/comments/1qfh6vg/free_gaussian_splatting_workflow/)

[23] [https://www.splatlabs.ai](https://www.splatlabs.ai/blog/what-are-gaussian-splats)
