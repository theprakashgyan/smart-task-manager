# Smart Site Task Manager

A hybrid task management application that saves time by automatically classifying tasks, assigning priorities, and extracting details using intelligent text analysis. Built with **Flutter**, **Node.js**, and **Supabase**.

## 🚀 Project Overview

This project was built to demonstrate a "Smart" workflow:
1.  **Smart Creation**: User types "Fix urgent bug in header".
2.  **Auto-Classification**: Backend detects "Technical" category and "High" priority.
3.  **Entity Extraction**: Backend extracts dates, people, and locations.
4.  **Actionable Suggestions**: backend suggests "Diagnose issue", "Git commit", etc.

## 🛠 Tech Stack

-   **Frontend**: Flutter (Riverpod for state management, Dio for API).
-   **Backend**: Node.js (Express.js).
-   **Database**: Supabase (PostgreSQL).
-   **Validation**: Zod.
-   **Testing**: Jest.

## ⚙️ Setup Instructions

### 1. Backend (Node.js)

1.  Navigate to the backend folder:
    ```bash
    cd smart-task-backend
    ```
2.  Install dependencies:
    ```bash
    npm install
    ```
3.  Set up environment variables in `.env`:
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_KEY=your_supabase_anon_key
    PORT=3000
    ```
4.  Run the server:
    ```bash
    node index.js
    ```

### 2. Database (Supabase)

1.  Create a new Supabase project.
2.  Go to the **SQL Editor**.
3.  Run the contents of `schema.sql` to create `tasks` and `task_history` tables.

### 3. Mobile App (Flutter)

1.  Navigate to the app folder:
    ```bash
    cd task_manager_app
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app:
    ```bash
    flutter run
    ```

## 📖 API Documentation

### `POST /api/tasks`
Create a new task with optional manual overrides.

**Request:**
```json
{
  "title": "Urgent meeting with John",
  "description": "Discuss budget",
  "category": "finance", // Optional override
  "priority": "high",    // Optional override
  "due_date": "2023-12-26T00:00:00.000Z",
  "assigned_to": "John"
}
```

### `POST /api/classify`
Preview classification results without saving.

**Request:**
```json
{
  "title": "Fix server crash",
  "description": ""
}
```

**Response:**
```json
{
  "category": "technical",
  "priority": "high",
  "suggested_actions": ["Diagnose issue", "Check logs"],
  "extracted_entities": {}
}
```

## 🏗 Architecture Decisions

-   **Layered Architecture in Flutter**: Separated `Models`, `Providers` (State), `Services` (API), and `Screens` (UI) for maintainability.
-   **Riverpod**: Selected for robust state caching and dependency injection (easy to mock for tests).
-   **Regex-based Logic**: Chosen for the backend "AI" to ensure deterministic, fast, and offline-capable classification without needing expensive LLM API calls for this demo.
-   **Supabase**: Chosen for instant Postgres setup and Row Level Security capabilities.

## 📸 Screenshots

*(Add your screenshots here)*
