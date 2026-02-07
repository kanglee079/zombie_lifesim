# Zombie LifeSim — Game Design Bible (Short, 10–15 pages)

Version: 0.1
Owner: Khang + Codex
Scope: Core loop, narrative arcs, endings, pillars, and UX scaffolding.

---

## 1. Vision (1–2 sentences)
Một thế giới hậu tận thế sống động, nơi mỗi quyết định (im lặng/đàm phán/bẫy) vừa tác động sinh tồn trước mắt vừa thay đổi lịch sử dài hạn của cộng đồng, dẫn đến nhiều kết cục khác nhau.

## 2. Pillars (Nguyên tắc thiết kế)
1. **Decision Weight**: Quyết định luôn có hậu quả ngắn hạn + dài hạn.
2. **Time Pressure**: Thời gian là tài nguyên thật (clock + day/night).
3. **Scarcity & Tradeoff**: Nước/đồ ăn luôn giới hạn; phải chọn ưu tiên.
4. **Narrative Integration**: Cốt truyện dẫn dắt hệ thống (quests, projects, map unlock).
5. **Progression Clarity**: Người chơi biết “tiếp theo làm gì”, “đang ở đâu”.

## 3. Target Audience & Experience
- Người thích survival + narrative + roguelite nhẹ.
- Muốn cảm giác “làm đúng thì sống, làm sai thì trả giá”, nhưng vẫn có hy vọng.
- Thời lượng mỗi session 5–15 phút, phù hợp mobile.

## 4. Core Loop (Vòng lặp chính)
1. **Morning Event** → 2. **Action Planning** → 3. **Explore/Craft/Project/Rest** → 4. **Resolve Outcomes** → 5. **Night Phase** → 6. **Daily Tick**

Mỗi ngày có 1–2 điểm nút cốt truyện (quest/event), kèm chiến lược tài nguyên.

## 5. Meta Loop (Vòng lặp dài hạn)
- **Dự án dài hạn**: water, defense, farming, radio.
- **Bản đồ mở rộng**: EP + quest + items.
- **Quyết định tuyến ending**: Escape / Fortress / Broadcast.

## 6. Systems Overview
### 6.1 Time & Clock
- Clock chạy theo thời gian thật.
- Mỗi hành động tiêu tốn phút.
- Sau 23:59, chỉ cho phép “end day”.

### 6.2 Survival Stats
- Hunger/Thirst/Fatigue/Stress/Infection.
- Thay đổi theo thời gian + hành động + sự kiện.
- “Critical thresholds” tạo cảm giác nguy cơ.

### 6.3 Base Stats
- Defense / Noise / Smell / Hope / SignalHeat / EP.
- Tác động trực tiếp đến event pool và night threat.

### 6.4 Projects (Long-term)
- Dự án là trục “sống lâu” thay vì chỉ loot.
- Dự án giúp tự chủ (water/food), đẩy người chơi vào lựa chọn đầu tư.

### 6.5 Quests & Narrative
- Quest stages kích hoạt bằng event + requirements.
- Mỗi quest có hint rõ ràng.
- Ending đến từ quest stage hoặc script resolve.

### 6.6 Scavenge & Loot
- Địa điểm có tag (water/food/medical...)
- Depletion giảm loot dần, buộc người chơi mở map mới.

## 7. Narrative Arcs (3 tuyến chính + 1 tuyến phụ)

### 7.1 Emerald (Escape)
- Chủ đề: “Hy vọng có thể là mồi nhử.”
- Mốc: radio → code → meet → convoy.
- Quyết định cuối: rời thành phố hay ở lại.

### 7.2 Fortress (Self-sustain)
- Chủ đề: “Ở lại, xây pháo đài, trả giá bằng hy sinh.”
- Mốc: garden bed → water security → defense → day 30 siege.
- Kết thúc: sống sót đêm 30.

### 7.3 Broadcast (Community)
- Chủ đề: “Gom người sống, đối mặt kẻ săn tín hiệu.”
- Mốc: radio relay → antenna → speaker → rules.
- Kết thúc: cộng đồng bền vững hoặc sụp đổ.

### 7.4 Listener Arc (Moral Choice)
- Bẫy / Đàm phán / Im lặng.
- Hậu quả kéo dài 2–3 ngày, ảnh hưởng base stats và tension.

## 8. Endings (Happy, Bittersweet, Bad)
- **Escape**: thành công / bittersweet / fail.
- **Fortress**: đứng vững / tổn thất nặng / sụp đổ.
- **Broadcast**: cộng đồng ổn định / bất ổn / bị săn.

Tiêu chí ending nên hiển thị rõ trong Quest Journal (dạng “Yêu cầu chính”).

## 9. Progression & Unlocks
- Trade unlock: day 5 hoặc gặp trader.
- Map unlock: day 7 hoặc explore 3+ locations.
- Projects unlock: day 3 + board intro.

## 10. Content Pipeline (Data-driven)
- **Events**: JSON, có groups, contexts, weight, flags.
- **Quests**: JSON + completionCondition.
- **Items/Recipes/Projects**: JSON, hint cho người chơi.

## 11. UX & Guidance
- **Objective panel** luôn gợi ý hành động tối ưu.
- **Quest Journal** là trung tâm dẫn dắt narrative.
- **Location tags** giúp tìm đúng tài nguyên.

## 12. Monetization (không pay-to-win)
- Cosmetic, story pack, season narrative.
- IAP chuẩn Apple/Google.

## 13. Live Ops & Events
- Mini arcs theo mùa (2–4 tuần).
- Event chain theo community online.

## 14. Success Metrics (MVP)
- D1 > 25%, D7 > 5%.
- Session length 7–12 phút.
- Conversion > 1.5% nếu có IAP.

## 15. Roadmap (High level)
- **Phase 1**: polish single-player + narrative clarity.
- **Phase 2**: async online (community board + trade).
- **Phase 3**: co-op session + faction.
- **Phase 4**: persistent world.

---

## Appendix: Core Loop Example
Day 4:
1. Morning event → “Scout EP”.
2. Player chooses “Explore gas station” (water tag).
3. Finds dirty water + purifier tablet.
4. Starts rain collector project.
5. Night attack event resolved.

End result: player feels agency + momentum toward ending.
