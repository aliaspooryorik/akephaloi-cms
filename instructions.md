I want to create a coldbox app using boxlang. 

The app will be a headless (hence the project name) CMS so needs to have a API module (returning JSON). The routing should include the language as part of the url. for example:

content/en/mypage - content in English
content/fr/mypage - content in French

I also needs to have a module where authorised (controlled by cbsecurity) users can login and perform CRUD operations (using cbwire for the front end and quick for the backend). It should run in docker and use SQLite as the database.

Content should be written in Markdown (use cbMarkdown), which is served as HTML in the API

Use cachebox to cache content served via the API

Users should be able to login using username and password or passkeys via the https://forgebox.io/view/cbsecurity-passkeys library

Use bootstrap CSS. As cbwire includes alpinejs you can use that to improve the UX.

## Questions to clarify requirements:

### Content Structure & API
1. What types of content will the CMS manage? (e.g., pages, blog posts, articles, media, categories, etc.)
2. What fields should each content type have? (e.g., title, body, slug, publish date, author, status, etc.)
3. Should the API support versioning? (e.g., `/api/v1/content/...`)
4. What API endpoints do you need? (e.g., GET all content, GET by slug, POST/PUT/DELETE for admin operations)
5. Should the API support filtering, sorting, and pagination?

#### Answers

1. The content will be used to provide inline help to end users. 
2. Each 'help' article will consist of a 'slug', 'language', 'title' and 'body'. It would also be useful to have properties for 'published' (boolean), created date, updated date.
3. The api should support versioning, initially using `v1`
4. API endpoints are only GET requests and can not be used to mutate data - only read
5. The API is simple and just returns the entry if it exists otherwise a JSON reponse indicating not found with 404 header

### Internationalization
1. Which languages do you want to support initially? (en, fr, others?)
2. Should content be translatable field-by-field, or completely separate content per language?
3. Do you need a fallback language if content isn't available in the requested language?

#### Answers
1. Routing for languages will be based on the slug. So a 'slug' of `content/en/mypage` will look in the database for the literal slug `en/mypage`. The languages are by convention not fixed.
2. Each entry in the database is independant, so you could have one entry for a `en/` prefixed slug and 100 for a `fr/` prefixed slug
3. If the entry is not found, return a 404. Do not fallback to a 'default' language

### Authentication & Authorization
1. What user roles do you need? (e.g., Admin, Editor, Author)
2. What specific permissions should each role have?
3. Should users be able to self-register, or admin-only user creation?
4. Do you need password reset functionality?

#### Answers
1. I need two roles:- Admin and Editor
2. Role Permissions
  - An admin who can do everything (CRUD for content and CRUD for users)
  - An editor who can do CRUD for content
3. Only admins can add users. Users can only change their own details
4. Add a password reset feature

### Admin Interface
1. What CRUD operations should be available in the admin? (manage content, users, settings?)
2. Should the admin interface be a separate module or integrated with the API module?
3. Do you need a dashboard/stats page?
4. Should there be a preview functionality for unpublished content?

#### Answers
1. Admin can perform all CRUD operations including manage content, users
2. The admin interface is it's own module. It is a web interface so needs layout etc and different security. The API just return JSON data.
3. Yes, add a dashboard/stats page?
4. Yes, there should be a preview functionality for unpublished content?

In addition users should be able to paginate, sort, filter and search content
In addition admins should be able to paginate, sort, filter and search users

### Technical Details
1. What BoxLang version should I target?
2. What ColdBox version should I use?
3. Should I use CommandBox for the project structure?
4. Do you need any specific Docker setup (e.g., specific base image, port configuration)?
5. Should the SQLite database be persistent via Docker volumes?
6. Do you need any specific logging or monitoring setup?

#### Answers
1. Use the latest stable BoxLang version
2. Use the latest stable ColdBox version
3. Use Docker to run the application. Use commandbox to configure the project
4. Use default settings for docker
5. The database should be persistent
6. Actions performed by users should be audited.

### Additional Features
1. Do you need SEO-friendly URLs and meta data management?
2. Should there be support for media/file uploads?
3. Do you need content scheduling (publish/unpublish at specific times)?
4. Should there be an audit trail for content changes?

#### Answers
1. Use SES style URLs which ColdBox already supports
2. Yes, authorised users should be able to upload image assets
3. Support content scheduling (publish/unpublish at specific times)
4. As mentioned about, audit content changes (and user changes)

## Follow-up Questions

### Database Schema
1. For the audit trail - should this be a separate `audit_log` table that tracks changes to both content and users?
2. For scheduled publishing - should there be `publish_date` and `unpublish_date` fields, or just a `publish_date` with the `published` boolean?
3. For image uploads - should images be stored in the database or filesystem? And should there be a separate `media` table to track uploaded files?

#### Answers
1. Yes use a seperate table for auditting
2. Support `publish_date` with the `published` boolean?
3. Images should be stored on the filesystem. note that one image may be used in more than one content entry (for example one image is common to each language version)

### Admin Interface Details
1. For the dashboard/stats page - what metrics would be useful? (e.g., total content count, published vs unpublished, recent activity, user activity?)
2. For pagination/sorting/filtering - what fields should be searchable/filterable for content? (title, slug, language, author, created date?)
3. For user management - what user fields do you need? (username, email, first name, last name, role, active status?)

#### Answers
1. Metrics to show would be most requested (via the CMS) content. This would be:
  - Total (all time)
  - For a time period (such as last week / last month / last year) 
2. You should be able to:
  - search for:
    - title & slug
  - filter by:
    - language, published & author
  - sort by:
    - title, language, published, author, created, updated
3. For user management - user fields are: username, email, first name, last name, role, active and password. 


### Technical Implementation
1. For content scheduling - should there be a background task that automatically publishes/unpublishes content at the scheduled times?
2. For the API caching - should cache invalidation happen automatically when content is updated through the admin interface?
3. For the preview functionality - should unpublished content be accessible via a special preview URL/token, or only within the admin interface?

#### Answers
1. For the publish. The way I see this working is that when the slug is first requested it will cache it. If it is not published (date / time is in the future) then return a 404 JSON response. Otherwise return JSON with the HTML content, title etc
2. cache invalidation happen automatically when content is updated through the admin interface
3. unpublished content be accessible via a special preview URL/token

### URL Structure
Just to confirm the routing structure:
- API: `/api/v1/content/{slug}` (where slug could be `en/mypage`, `fr/mypage`, etc.)
- Admin: `/admin/...` (login, dashboard, content management, user management)
- Is this correct?

#### Answers
Yes. API is public, Admin is secured. There will also need to be a public way to preview unpublished slugs

## Implementation Outline

Based on your requirements, here's what I will create:

### Project Structure
```
akephaloi-cms/
├── Application.bx
├── box.json
├── server.json
├── docker-compose.yml
├── Dockerfile
├── config/
│   ├── CacheBox.cfc
│   ├── ColdBox.cfc
│   ├── Router.cfc
│   └── WireBox.cfc
├── handlers/
│   └── Main.bx
├── interceptors/
│   └── Security.bx
├── layouts/
│   └── Main.cfm
├── models/
│   ├── entities/
│   │   ├── Content.bx
│   │   ├── User.bx
│   │   ├── Media.bx
│   │   └── AuditLog.bx
│   └── services/
│       ├── ContentService.bx
│       ├── UserService.bx
│       ├── MediaService.bx
│       └── AuditService.bx
├── modules/
│   ├── api/
│   │   ├── ModuleConfig.bx
│   │   ├── handlers/
│   │   │   └── Content.bx
│   │   └── views/
│   └── admin/
│       ├── ModuleConfig.bx
│       ├── handlers/
│       │   ├── Main.bx
│       │   ├── Content.bx
│       │   ├── Users.bx
│       │   ├── Media.bx
│       │   └── Auth.bx
│       ├── layouts/
│       │   └── Main.cfm
│       └── views/
│           ├── main/
│           ├── content/
│           ├── users/
│           ├── media/
│           └── auth/
├── resources/
│   ├── database/
│   │   └── migrations/
│   └── assets/
│       ├── css/
│       ├── js/
│       └── uploads/
└── views/
    └── main/
        └── index.cfm
```

### Database Schema
1. **Content Table**: id, slug, title, body, published, publish_date, author_id, created_date, updated_date
2. **Users Table**: id, username, email, first_name, last_name, password, role, active, created_date, updated_date
3. **Media Table**: id, filename, original_name, path, mime_type, size, uploaded_by, created_date
4. **Audit_Log Table**: id, table_name, record_id, action, old_values, new_values, user_id, created_date

### Key Features Implementation

#### API Module (`/modules/api/`)
- **Content Handler**: GET `/api/v1/content/{slug}` endpoint
- **Caching**: CacheBox integration with automatic invalidation
- **Response Format**: JSON with HTML (converted from Markdown)
- **Preview**: Special preview endpoint with token authentication

#### Admin Module (`/modules/admin/`)
- **Authentication**: CBSecurity + Passkeys integration
- **Dashboard**: Stats showing most requested content (all-time & time periods)
- **Content Management**: CRUD with CBWire frontend
  - Search: title & slug
  - Filter: language, published, author
  - Sort: title, language, published, author, created, updated
  - Pagination support
- **User Management**: CRUD for admins
  - Pagination, search, filter capabilities
- **Media Management**: Image upload and management
- **Preview**: Unpublished content preview functionality

#### Core Services
- **ContentService**: Business logic for content operations
- **UserService**: User management and authentication
- **MediaService**: File upload and management
- **AuditService**: Logging all CRUD operations

#### Security & Features
- **CBSecurity**: Role-based access control (Admin/Editor)
- **Passkeys**: Alternative authentication method
- **Password Reset**: Email-based password reset
- **Audit Trail**: All content and user changes logged
- **Scheduled Publishing**: Content published based on publish_date
- **Markdown Processing**: CBMarkdown for content rendering

#### Docker Setup
- **Base Image**: CommandBox with BoxLang
- **Database**: SQLite with persistent volume
- **Port**: Default 8080
- **Volumes**: Database and uploads directory

### Technology Stack
- **BoxLang**: Latest stable version
- **ColdBox**: Latest stable version
- **CBSecurity**: Authentication and authorization
- **CBWire**: Frontend interactivity
- **Quick ORM**: Database operations
- **CBMarkdown**: Markdown processing
- **CacheBox**: Content caching
- **CBSecurity-Passkeys**: Passkey authentication

### URL Structure
- **API**: `/api/v1/content/{slug}` (public)
- **Admin**: `/admin/*` (secured)
- **Preview**: `/preview/{token}/{slug}` (public with token)

