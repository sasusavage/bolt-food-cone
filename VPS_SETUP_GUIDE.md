# VPS Setup Guide — Campus Eats (Coolify)

## Step 1: PostgreSQL Service in Coolify

1. Coolify Dashboard → **+ New Resource → Database → PostgreSQL**
2. Set:
   - Database name: `campus_eats`
   - Username: `campus_user`
   - Password: a strong password
3. Under **Storage**, add a persistent volume:
   - Container path: `/var/lib/postgresql/data`
   - This ensures your data survives container restarts/updates
4. Click **Deploy**
5. Note the **internal** connection string shown by Coolify, e.g.:
   `postgresql://campus_user:yourpassword@postgres-xxxx:5432/campus_eats`
   (Use this internal URL in your Flask env — it never leaves your VPS network)

---

## Step 2: Deploy the Flask API

1. Push the `backend/` folder to GitHub or your Gitea instance
2. In Coolify → **+ New Resource → Application**
3. Connect your Git repo. Coolify auto-detects the `Dockerfile`
4. Under **Environment Variables**, add:

   | Key | Value |
   |-----|-------|
   | `DATABASE_URL` | `postgresql://campus_user:yourpassword@postgres-xxxx:5432/campus_eats` |
   | `JWT_SECRET` | Run `python -c "import secrets; print(secrets.token_hex(32))"` and paste the output |
   | `UPLOAD_FOLDER` | `/app/uploads/menu_images` |
   | `FLASK_ENV` | `production` |
   | `MAX_CONTENT_LENGTH` | `5242880` |

5. Under **Storage**, add a **persistent volume** for menu images:
   - Container path: `/app/uploads/menu_images`
   - This is critical — without it, every deploy wipes your uploaded images

6. Under **Network**, expose port `5000`
7. Assign a domain (e.g., `api.campuseats.vvu.edu.gh`)
   - Coolify handles Let's Encrypt SSL automatically
8. Click **Deploy**

---

## Step 3: Initialize the Database

After deploy, open the Flask container terminal in Coolify (or SSH in):

```bash
flask db upgrade
```

If this is the first time:
```bash
flask db init
flask db migrate -m "initial schema"
flask db upgrade
```

---

## Step 4: Create the First Admin User

In the Flask container terminal:

```bash
python - <<'EOF'
from app import create_app, db
from app.models import User

app = create_app()
with app.app_context():
    admin = User(name='Admin', email='admin@vvu.edu.gh', role='admin')
    admin.set_password('ChangeMe123!')
    db.session.add(admin)
    db.session.commit()
    print('Admin user created: admin@vvu.edu.gh')
EOF
```

**Change the password immediately after first login.**

---

## Step 5: Configure Flutter App

Open `campus_eats_app/lib/core/constants.dart` and update:

```dart
static const String baseUrl = 'https://api.campuseats.vvu.edu.gh'; // your domain
static const String tomTomApiKey = 'YOUR_KEY_HERE';
```

---

## Step 6: Get Your TomTom API Key

1. Go to **https://developer.tomtom.com** → Sign up (free tier available)
2. Create an application → copy the **API Key**
3. Paste it into `AppConstants.tomTomApiKey`
4. The app uses **TomTom Fuzzy Search API**, biased to:
   - Ghana (`countrySet=GH`)
   - 20km radius around VVU campus coordinates

---

## How Image Uploads Work

```
Admin Flutter App
      │
      ▼
POST /api/admin/menu  (multipart/form-data with image file)
      │
      ▼
Flask saves image to /app/uploads/menu_images/<uuid>.jpg
      │  (persistent volume — survives container updates)
      ▼
Flask returns full image URL:
  https://api.campuseats.vvu.edu.gh/uploads/menu_images/<uuid>.jpg
      │
      ▼
Flutter CachedNetworkImage displays it
```

---

## API Endpoint Reference

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/register` | None | Register student |
| POST | `/api/auth/login` | None | Login, get JWT |
| GET | `/api/auth/me` | JWT | Get current user |
| GET | `/api/menu/` | JWT | List menu items |
| GET | `/api/menu/categories` | JWT | List categories |
| POST | `/api/orders/place` | JWT | Place order (atomic) |
| GET | `/api/orders/my-orders` | JWT | Student's order history |
| GET | `/api/orders/:id` | JWT | Single order detail |
| POST | `/api/admin/menu` | Admin JWT | Create menu item + image |
| PATCH | `/api/admin/menu/:id` | Admin JWT | Update menu item |
| POST | `/api/admin/menu/:id/image` | Admin JWT | Replace item image |
| DELETE | `/api/admin/menu/:id` | Admin JWT | Delete menu item |
| GET | `/api/admin/orders` | Admin JWT | All orders |
| PATCH | `/api/admin/orders/:id/status` | Admin JWT | Update order status |

---

## Troubleshooting

**DB connection refused**
- Ensure Flask app and Postgres are in the same Coolify network
- Use the internal hostname Coolify shows, not `localhost`

**Images not showing in app**
- Check that the persistent volume is mounted at `/app/uploads/menu_images`
- Verify `UPLOAD_FOLDER` env var matches exactly

**JWT errors / 401s**
- Check `JWT_SECRET` is set in Flask env
- Token expires after default 1 hour — handle refresh or re-login in Flutter

**CORS errors**
- `flask-cors` is configured for all origins
- For production, restrict to your Flutter app's domain in `create_app()`

**Order placement fails with 409**
- The atomic transaction caught insufficient stock
- The error message names the specific item — show it to the user
