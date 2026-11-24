How the flattened texture is produced (current logic)

1. Source data — the pot is a photogrammetry scan split into 4 chunks (pot_round_quad1–4), each with its own baked texture. The pot is a surface of revolution about the Z axis; the chunks meet at 0°, 90°, 180°, 270°.
2. Outside-only selection — for each chunk a BVH ray is cast from outside; only faces whose center is the first surface hit are kept (outer wall only; interior wall, rim top, base underside dropped).
3. Cylindrical unroll (roller projection) — every vertex gets UVs straight from world space:
- u = angle around Z / 360° (so left→right = around the pot)
- v = (z − zmin) / height (bottom→top = base→rim)
  The same mapping for all 4 chunks, so the unrolled pieces line up. Baking is done over an extended ±4° range and then cropped to exactly 360°, so nothing is clipped at the wrap.
4. Albedo bake — Cycles Diffuse Color (no lighting) bakes each chunk's original 4K atlas texture through this new roller UV → four rectangular images, each covering its ~90° (plus ~0.2° overlap).
5. Merge — the four rectangles are combined with smooth angular weights (feather ≈ 0.7°), plus corrections: per-chunk edge-falloff gain, seam level matching, wrap cross-fade bridge, hole inpainting → the 8192×2282 PNG.
6. Display object — pot_rollout uses the same roller UVs, so the PNG wraps the pot 1:1 (this is why the Blender view and the flat image show the same seams).
