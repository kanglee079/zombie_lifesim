# Zombie LifeSim — Technical Design Doc

Version: 0.1
Scope: Backend, data schema, anti-cheat, telemetry, and online roadmap.

---

## 1. Goals
- Enable online features without breaking core single-player.
- Support async gameplay first, then co-op sessions, then persistent world.
- Ensure security, fairness, and telemetry from day 1.

## 2. Architecture (High-level)
**Phase 1 (Async online)**
- Client (Flutter) → API Gateway → Game Services → Database.
- Services: Auth, Profile, WorldSeed, Market, Community Board.

**Phase 2 (Co-op session)**
- Session Service (matchmaking + room state).
- Server authoritative resolution for co-op events.

**Phase 3 (Persistent world)**
- World shards (per season/region).
- Periodic world ticks + faction state.

## 3. Backend Stack Options
- **MVP**: Firebase Auth + Firestore + Cloud Functions.
- **Scale**: Node/Go + Redis + Postgres + S3 + Cloud Run/K8s.

## 4. Data Model (Core)
### 4.1 User
```
User {
  id: string,
  email?: string,
  createdAt: timestamp,
  lastSeenAt: timestamp,
  deviceId: string,
  platform: ios|android,
  locale: string
}
```

### 4.2 PlayerProfile
```
PlayerProfile {
  userId: string,
  displayName: string,
  avatarId: string,
  currency: int,
  premiumFlags: [string],
  stats: {
    totalDaysSurvived: int,
    endingsUnlocked: [string]
  }
}
```

### 4.3 SaveSlot
```
SaveSlot {
  id: string,
  userId: string,
  stateBlob: json,
  version: string,
  lastSaveAt: timestamp
}
```

### 4.4 WorldSeed
```
WorldSeed {
  id: string,
  seasonId: string,
  seed: int,
  mapConfig: json,
  active: bool
}
```

### 4.5 CommunityBoard (Async)
```
CommunityBoardPost {
  id: string,
  userId: string,
  text: string,
  tags: [string],
  createdAt: timestamp,
  moderationStatus: pending|approved|rejected
}
```

### 4.6 Market Listings (Async Trade)
```
MarketListing {
  id: string,
  userId: string,
  itemId: string,
  qty: int,
  price: int,
  createdAt: timestamp,
  expiresAt: timestamp
}
```

## 5. Network Protocols
- **REST** for async features.
- **WebSocket** for session-based co-op.
- All payloads signed with server timestamp + nonce.

## 6. Anti-Cheat
### 6.1 Client-side
- Obfuscate critical values in local save.
- Detect tampering by hashing (state + salt).

### 6.2 Server-side
- Server authoritative for critical actions (trade, co-op, rewards).
- Rate limits per device/user.
- Event-based anomaly detection.

### 6.3 Economy Integrity
- Transactions stored as immutable ledger.
- Reconciliation job to detect abnormal currency gains.

## 7. Telemetry (Must-have Events)
### Session
- app_open, session_start, session_end
- day_start, day_end
- time_spent_per_day

### Core Systems
- scavenge_start, scavenge_end (location, risk, loot)
- project_start, project_complete
- trade_buy, trade_sell
- radio_use, noise_peak

### Narrative
- quest_start, quest_stage, quest_complete
- ending_reached (id, grade)

### Economy
- iap_view, iap_purchase_success, iap_cancel

## 8. Data Pipeline
- Raw events → Stream → Warehouse (BigQuery/Postgres)
- Daily aggregation: D1/D7/D30, ARPDAU, funnel drop.

## 9. Security & Privacy
- GDPR/CCPA compliance.
- PII minimized; no storage of raw text without moderation.
- Content moderation for UGC.

## 10. Offline-First Strategy
- Local save = authoritative for offline mode.
- Sync on reconnect with conflict resolution.
- For async features, queue actions locally.

## 11. Deployment
- CI/CD pipeline with staged environments.
- Feature flagging (remote config) for live ops.

## 12. Roadmap
- **Phase 1**: Auth + Save Sync + Community Board.
- **Phase 2**: Async Trade + seasonal leaderboards.
- **Phase 3**: Co-op events.
- **Phase 4**: Persistent world & factions.

---

## Appendix: Telemetry Example Payload
```
{
  "event": "scavenge_end",
  "userId": "u_123",
  "sessionId": "s_456",
  "day": 5,
  "location": "gas_station",
  "loot": {"water_bottle": 2, "wire": 1},
  "risk": 0.22,
  "timestamp": 1710000000
}
```
