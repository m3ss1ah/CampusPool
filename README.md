# 🚗 CampusPool: Student Commute Coordination Platform

[![Stack](https://img.shields.io/badge/Stack-Flutter%20%7C%20Node.js%20%7C%20PostgreSQL-blue.svg?style=for-the-badge)](https://github.com/m3ss1ah/CampusPool)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](#)
[![Android](https://img.shields.io/badge/Platform-Android%20%7C%20Mobile-orange.svg?style=for-the-badge)](#)

CampusPool is a high-fidelity, production-grade monorepo containing a mobile-first peer-to-peer commute coordination application designed exclusively for college students. By enabling real-time ride-sharing, dynamic map discovery, secure messaging, and robust geolocation features, CampusPool connects students traveling along similar routes, reducing travel costs and minimizing environmental impact.

This repository is organized as a monorepo consisting of:
*   **`mobile/`**: A modern Material 3, Riverpod-powered, custom map-native Flutter application for Android.
*   **`backend/`**: A scalable Node.js + Express.js API engine built with raw `pg` PostgreSQL pools, PostGIS geospatial indexing, socket-driven real-time messaging, and Cloudinary uploads.

---

## 📖 Table of Contents
1. [Core Features](#-core-features)
2. [Technology Stack](#%EF%B8%8F-technology-stack)
3. [System Architecture](#-system-architecture)
4. [Database Schema (Mermaid ERD)](#-database-schema-mermaid-erd)
5. [Key Feature Deep-Dives](#-key-feature-deep-dives)
    * [Coordinate Privacy System (Geofence Masking)](#1-coordinate-privacy-system-geofence-masking)
    * [Normalized Destination Matching (Trigram Alias Matching)](#2-normalized-destination-matching-trigram-alias-matching)
6. [UI/UX Design Philosophy](#-uiux-design-philosophy)
7. [Repository Folder Structure](#-repository-folder-structure)
8. [Installation & Local Setup](#%EF%B8%8F-installation--local-setup)
    * [Backend Engine Setup](#1-backend-engine-setup)
    * [Flutter Mobile App Setup](#2-flutter-mobile-app-setup)
9. [API Interface Reference](#-api-interface-reference)
10. [Version 1.1 Action Plan & Issue Resolution](#%EF%B8%8F-version-1.1-action-plan--issue-resolution)

---

## 🌟 Core Features

*   🗺️ **Interactive Geolocation Map**: Real-time render of available commutes plotted within a student's search radius using OpenStreetMap custom vector tiles. Integrates **OSRM Routing** to dynamically draw accurate driving `PolylineLayer` paths on the map.
*   🔒 **Enterprise Coordinate Privacy & Trust**: Strict `.edu` email domain verification ensures a secure student-only network. Dual-tier location masking completely hides precise source locations (rounded to ~500m precision) for public browsers, revealing them only to accepted riders.
*   ⚡ **Advanced PostGIS Matching**: Intelligent ride search powered by PostgreSQL and PostGIS `ST_DWithin` and `ST_Distance` functions for highly accurate geospatial matching.
*   💬 **Instant Socket Chat & Offline Caching**: Real-time communication channels opened automatically between accepted passengers and ride creators. Uses a resilient **offline-first caching architecture** via `Hive`, ensuring instant load times even on spotty campus Wi-Fi.
*   🔔 **Push Notification Infrastructure**: Background/foreground alerts for new messages and ride requests powered by the Firebase Admin SDK and Firebase Cloud Messaging (FCM).
*   🚘 **Intelligent Seat constraints**: Structured vehicle categories enforcing strict seat constraints:
    *   **Bike/2-Wheeler**: Max 1 seat.
    *   **Auto-Rickshaw**: Max 2 seats.
    *   **Car (Sedan/Hatchback)**: Max 4 seats.
    *   **SUV**: Max 7 seats.

---

## 🛠️ Technology Stack

### Mobile Frontend (Flutter)
*   **Framework**: Flutter 3.x Stable & Dart 3.x
*   **State Management**: `flutter_riverpod` + `riverpod_annotation` utilizing code generated `AsyncNotifier` structures for high stability.
*   **Navigation**: `go_router` supporting deep-linking, animated transitions, and auth-guarded routing.
*   **Mapping**: `flutter_map` coupled with `flutter_map_tile_caching` to eliminate startup network stutters and cache standard OpenStreetMap tiles locally.
*   **Real-time Handlers**: `socket_io_client` configured with auto-reconnect listeners.
*   **Data Caching**: `hive_flutter` + `hive_generator` for low-latency persistence of recent conversations and offline-first commute cards.
*   **HTTP Layer**: `dio` client singleton with a centralized JWT injection interceptor and standard JSON validation.

### API Backend (Express.js)
*   **Runtime**: Node.js 20.x LTS
*   **Framework**: Express.js
*   **Websockets**: Socket.IO configured for secure session pairing.
*   **Database Client**: Raw `pg` pool queries interacting directly with PostgreSQL (Supabase Hosting).
*   **Security & Sanitization**: `helmet` security headers, `xss-clean` input sanitization, `hpp` HTTP parameter pollution protection, and `express-rate-limit` configuration.
*   **Validation**: Robust `express-validator` middleware asserting schemas at route gates.
*   **Media Hosting**: Cloudinary Node SDK for high-performance profile image storage.
*   **Push Broker**: `firebase-admin` executing immediate notification push protocols.

### Database & Geographics
*   **Database Engine**: PostgreSQL 15 hosting.
*   **Geospatial Processing**: PostGIS 3.x (`GEOGRAPHY` types and `GIST` indexes).
*   **Host**: Supabase (Free Tier direct connection string pool).

---

## 📐 System Architecture

The following diagram details the transaction flow of CampusPool—from mobile clients through local services, standard routes, socket loops, to the PostGIS spatial database.

```mermaid
graph TD
    A[Flutter App] -->|HTTP Requests| B[Express Gateway]
    A -->|WebSocket Stream| C[Socket.IO Server]
    
    B -->|JWT Verification| D[Auth Middleware]
    B -->|Input Verification| E[Validator Middleware]
    
    D --> F[Modules]
    E --> F
    
    F -->|Auth/Profile| G[Users Module]
    F -->|Geospatial Queries| H[Commutes Module]
    F -->|Seat Bookings| I[Requests Module]
    F -->|Trigram Fuzzy Search| J[Matching Module]
    F -->|Real-Time Storage| K[Chat Module]
    
    G -->|Direct pg Pool SQL| L[(PostgreSQL Database)]
    H -->|PostGIS Spatial Index| L
    I -->|Transactional SQL| L
    J -->|pg_trgm Similarity| L
    K -->|Cursor Queries| L
    
    K -.->|Emits Messages| C
    C -.->|Real-time Socket Update| A
    
    G -->|Image Uploads| M[Cloudinary SDK]
    I -.->|Triggers Push Notification| N[FCM Service]
    N -.->|Firebase Cloud Messaging| A
```

---

## 🗄️ Database Schema (Mermaid ERD)

All operational database tables are built with direct referential integrity and spatial indexing. This Entity-Relationship Diagram outlines the database architecture:

```mermaid
erDiagram
    USERS {
        UUID id PK
        VARCHAR full_name
        VARCHAR email UK
        VARCHAR password_hash
        VARCHAR phone
        VARCHAR college
        TEXT profile_pic_url
        TEXT fcm_token
        BOOLEAN has_vehicle
        VARCHAR vehicle_type
        INT total_rides_offered
        INT total_rides_joined
        BOOLEAN is_active
        TIMESTAMPTZ created_at
    }

    COMMUTES {
        UUID id PK
        UUID creator_id FK
        VARCHAR source_label
        GEOGRAPHY source_location
        FLOAT source_lat
        FLOAT source_lng
        VARCHAR dest_label
        VARCHAR dest_label_normalized
        GEOGRAPHY dest_location
        FLOAT dest_lat
        FLOAT dest_lng
        TIMESTAMPTZ departure_time
        INT total_seats
        INT available_seats
        VARCHAR vehicle_type
        TEXT notes
        VARCHAR status
        TIMESTAMPTZ created_at
    }

    RIDE_REQUESTS {
        UUID id PK
        UUID commute_id FK
        UUID requester_id FK
        VARCHAR status
        TEXT message
        TIMESTAMPTZ created_at
    }

    CONVERSATIONS {
        UUID id PK
        UUID commute_id FK
        UUID participant_a FK
        UUID participant_b FK
        TEXT last_message
        TIMESTAMPTZ last_message_at
        TIMESTAMPTZ created_at
    }

    MESSAGES {
        UUID id PK
        UUID conversation_id FK
        UUID sender_id FK
        TEXT content
        BOOLEAN is_read
        TIMESTAMPTZ deleted_at
        TIMESTAMPTZ created_at
    }

    NOTIFICATIONS {
        UUID id PK
        UUID user_id FK
        VARCHAR type
        VARCHAR title
        TEXT body
        JSONB metadata
        BOOLEAN is_read
        TIMESTAMPTZ created_at
    }

    DESTINATION_ALIASES {
        UUID id PK
        VARCHAR alias UK
        VARCHAR canonical
        VARCHAR city
    }

    USERS ||--o{ COMMUTES : creates
    USERS ||--o{ RIDE_REQUESTS : requests
    COMMUTES ||--o{ RIDE_REQUESTS : contains
    COMMUTES ||--o| CONVERSATIONS : associated-with
    USERS ||--o{ CONVERSATIONS : participant-a
    USERS ||--o{ CONVERSATIONS : participant-b
    CONVERSATIONS ||--o{ MESSAGES : groups
    USERS ||--o{ MESSAGES : sends
    USERS ||--o{ NOTIFICATIONS : receives
```

---

## 🔒 Key Feature Deep-Dives

### 1. Coordinate Privacy System (Geofence Masking)

To protect student safety during the dynamic matching and map-browsing phases, CampusPool uses a **dual-tier geofence privacy engine** built directly into the SQL serialization layer:

```
[COMMUTE PIN MAP / BROWSE VIEW]
  ├── Coordinates rounded to ~500m precision (2 decimal places)
  └── Precise origin/destination coordinates are MASKED.
                 ↓ (Ride Request Submitted)
[CREATOR ACCEPTS PASSENGER REQUEST]
  ├── Database verification checks for state = 'accepted'
  └── Precise origin coordinates UNLOCKED for accepted passenger & creator ONLY.
```

#### SQL/JS Privacy Implementation Snippet:
```javascript
// src/utils/privacy.js
const roundCoordinate = (coord, precision = 2) => parseFloat(coord.toFixed(precision));

const applyCoordinatePrivacy = (commute, userId, acceptedParticipantIds = []) => {
  const isCreator  = commute.creator_id === userId;
  const isAccepted = acceptedParticipantIds.includes(userId);

  if (isCreator || isAccepted) {
    return commute; // Expose exact coordinates
  }

  // Obfuscate coordinates for the public
  return {
    ...commute,
    source_lat: roundCoordinate(commute.source_lat, 2), // ~500m accuracy
    source_lng: roundCoordinate(commute.source_lng, 2),
    dest_lat: roundCoordinate(commute.dest_lat, 3),    // ~100m accuracy
    dest_lng: roundCoordinate(commute.dest_lng, 3),
  };
};
```

---

### 2. Normalized Destination Matching (Trigram Alias Matching)

Different students type the same destination in multiple ways (e.g., `"BKC"`, `"bkc mumbai"`, `"Bandra Kurla Complex"`). CampusPool implements a canonical lookup system with PostgreSQL trigram matches (`pg_trgm`) to optimize search results:

1.  **Normalization**: Custom utilities strip punctuation, lowercase strings, and search for matches in the `destination_aliases` table.
2.  **Canonical Conversion**: Common inputs are mapped directly to canonical keys (e.g., `"bandra_kurla_complex"`).
3.  **Fuzzy Searching**: If an exact alias is not found, the system performs a trigram similarity query on `dest_label_normalized` to identify the most relevant commute candidates.

---

## 🎨 UI/UX Design Philosophy

CampusPool stands out with a **Neo-Brutalist inspired design system** optimized for clear visual hierarchy:

*   🏁 **High Contrast Color Palette**: Curator-selected deep colors, pure blacks, and neon highlights. Unnecessary details are removed in favor of high-contrast cards and tactile icons.
*   📐 **Structured Geometry**: High-contrast, thick borders (`2px` solid black) on input fields, buttons, and panels, accented by flat shadows.
*   🌴 **Dynamic Top Island**: A custom dashboard element inspired by modern dynamic islands that expands to show active ride states, current destination routes, and system alerts.
*   ⏱️ **Countdown Sliders**: Real-time, shrinking progress sliders on nearby commute cards that show the remaining time until departure to create a sense of urgency.
*   🌈 **Strategic Color Codes**: Your own active commutes are automatically rendered on the map in **Red** to stand out, while other commutes are shown in standard system colors.

---

## 📂 Repository Folder Structure

```
CampusPool/
├── .gitignore                   # Root gitignore (ignoring node_modules, builds, and master spec .mds)
├── README.md                    # Primary repository index
├── campuspool_antigravity_master_v2.md  # [IGNORED] Core system specs
├── campuspool_v1_report.md      # [IGNORED] Phase 1 debug report
│
├── backend/                     # Node.js Express Engine
│   ├── src/
│   │   ├── index.js             # Entry Point
│   │   ├── app.js               # Application setup (CORS, Helmet, express-validator)
│   │   ├── socket.js            # Real-time WebSocket connection engine
│   │   ├── config/              # Database pool, Cloudinary, and FCM initialization
│   │   ├── modules/             # Auth, Users, Commutes, Requests, Chat, and Upload services
│   │   ├── middleware/          # JWT, schema validation, and rate limiter guards
│   │   └── utils/               # PostGIS geofencing and destination normalization helpers
│   ├── migrations/              # PostgreSQL raw SQL migrations (001 to 008)
│   ├── .env.example             # Template for API environmental configurations
│   └── package.json             # Backend dependencies
│
└── mobile/                      # Flutter Application
    ├── lib/
    │   ├── main.dart            # Application entry
    │   ├── app.dart             # GoRouter setup
    │   ├── core/                # Dio client, secure storage, and notification singletons
    │   ├── features/            # Auth, Map view, Commute lifecycle, Chat rooms, and User Profiles
    │   └── shared/              # Neo-Brutalist UI buttons, fields, cards, and animations
    ├── pubspec.yaml             # Dart packages
    └── .env.example             # Mobile development host mappings
```

---

## ⚙️ Installation & Local Setup

### Prerequisites
*   [Node.js (v20.x or higher)](https://nodejs.org/)
*   [Flutter SDK (v3.x or higher)](https://flutter.dev/docs/get-started/install)
*   A running PostgreSQL database with **PostGIS** enabled (e.g., on [Supabase](https://supabase.com/)).

---

### 1. Backend Engine Setup

1.  Navigate to the backend directory:
    ```bash
    cd backend
    ```
2.  Install dependencies:
    ```bash
    npm install
    ```
3.  Configure your environment variables:
    ```bash
    cp .env.example .env
    ```
    Open `.env` and configure your credentials:
    ```env
    PORT=5000
    NODE_ENV=development
    DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres
    JWT_SECRET=your_super_secret_jwt_key
    JWT_EXPIRES_IN=30d
    ```
4.  Run SQL migrations:
    Open your PostgreSQL client or the Supabase SQL Editor and execute the raw migrations in order from [backend/migrations](file:///c:/Users/vrain/OneDrive/Desktop/CampusPool/backend/migrations):
    *   `001_create_extensions.sql` (Enables PostGIS, pg_trgm, UUIDs)
    *   `002_create_users.sql`
    *   `003_create_commutes.sql` (Initializes geospatial geography properties)
    *   `004_create_requests.sql`
    *   `005_create_conversations.sql`
    *   `006_create_messages.sql`
    *   `007_create_notifications.sql`
    *   `008_create_destination_aliases.sql` (Populates Mumbai-specific fuzzy mapping keys)

5.  Start the development server:
    ```bash
    npm run dev
    ```

---

### 2. Flutter Mobile App Setup

1.  Navigate to the mobile directory:
    ```bash
    cd mobile
    ```
2.  Install the required packages:
    ```bash
    flutter pub get
    ```
3.  Create the environment configuration file:
    ```bash
    cp .env.example .env
    ```
    Open `.env` and set the target API base URL:
    *   For the **Android Emulator**: Use `http://10.0.2.2:5000` (bridges local port 5000 through the virtual machine host).
    *   For **Physical Devices**: Use your machine's local IP address (e.g., `http://192.168.1.100:5000`).
4.  Generate dependencies and Riverpod files:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
5.  Launch the application:
    ```bash
    flutter run
    ```

---

## 📡 API Interface Reference

All responses return a structured JSON body matching this format:
*   **Success**: `{ "success": true, "data": { ... }, "message": "Details" }`
*   **Failure**: `{ "success": false, "error": "CODE_ERROR", "message": "Details" }`

| Request Method | Endpoint | Authorization | Description |
| :--- | :--- | :--- | :--- |
| **POST** | `/api/auth/register` | Public | Registers a user (validates email structure, hashes credentials). |
| **POST** | `/api/auth/login` | Public | Authenticates credentials and returns a signed JWT. |
| **PATCH** | `/api/auth/fcm-token` | Bearer Token | Updates FCM tokens on startup. |
| **GET** | `/api/users/profile` | Bearer Token | Retrieves authenticated profile data. |
| **PATCH** | `/api/users/profile` | Bearer Token | Updates profile details (has_vehicle parameters, Cloudinary URLs). |
| **POST** | `/api/commutes` | Bearer Token | Creates a new commute listing (saves source/dest PostGIS geographies). |
| **GET** | `/api/commutes/nearby` | Bearer Token | Retrieves open rides within a radius (applies coordinate privacy). |
| **GET** | `/api/commutes/:id` | Bearer Token | Retrieves detailed commute logs (unlocks full geofence if accepted). |
| **POST** | `/api/commutes/:id/requests`| Bearer Token | Requests a seat in a commute. |
| **PATCH** | `/api/requests/:id` | Bearer Token | Approves or rejects seat requests (triggers FCM notifications). |
| **GET** | `/api/matching/suggestions`| Bearer Token | Returns commutes matching custom user criteria. |
| **GET** | `/api/chat/conversations` | Bearer Token | Retrieves recent real-time chat threads. |
| **GET** | `/api/chat/conversations/:id/messages` | Bearer Token | Retrieves paginated messages using a scroll cursor. |

---

## 🚀 Interview-Ready Project Enhancements

This project has been fully upgraded to a production-ready state with the following advanced features implemented:

1.  **Security & Trust**: Integrated strict `.edu` email domain validation on registration to enforce a verified student-only network.
2.  **Visual Routing**: Implemented dynamic map Polylines by fetching coordinate geometries from the public OSRM routing API to visually trace commutes.
3.  **Performant Geospatial Matching**: Migrated from basic Haversine distance calculations to native **PostGIS `ST_DWithin`** functions, allowing the database to intelligently match overlapping commute trajectories.
4.  **Offline-First Resilience**: Configured a `Hive` NoSQL local database to aggressively cache conversations and messages, providing instantaneous hydration even without network connectivity.
5.  **Background Push Capabilities**: Initialized the `firebase-admin` SDK on the Node.js backend to fire seamless FCM background notifications to target devices.

---
*Created with 💙 by CampusPool developers. Let's make campus commutes collaborative, secure, and sustainable.*
