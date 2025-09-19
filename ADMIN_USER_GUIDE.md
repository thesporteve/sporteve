# SportEve Admin Portal - User Guide

## Table of Contents
1. [Getting Started](#getting-started)
2. [User Roles & Permissions](#user-roles--permissions)
3. [News Article Management](#news-article-management)
4. [Sports Wiki Management](#sports-wiki-management)
5. [AI Content Generation](#ai-content-generation)
6. [Content Review & Approval](#content-review--approval)
7. [Content Management Hub](#content-management-hub)
8. [Admin Management](#admin-management)
9. [Push Notifications](#push-notifications)
10. [Responsive Design & Mobile Usage](#responsive-design--mobile-usage)
11. [Best Practices](#best-practices)
12. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Accessing the Admin Portal
1. Navigate to the SportEve Admin Portal URL
2. Enter your admin credentials (email and password)
3. Click "Login" to access the dashboard

### Dashboard Overview
After logging in, you'll see the main dashboard with:
- Navigation sidebar (desktop) or bottom navigation (mobile)
- Quick access to all major features
- Role-based feature visibility

---

## User Roles & Permissions

### Admin Roles
The system supports two types of administrators:

#### **Regular Admin**
- ✅ News Article Management (create, edit, delete, publish)
- ✅ Sports Wiki Management (full access)
- ❌ AI Content Generation (restricted)
- ❌ Content Review (restricted)
- ❌ Content Management Hub (restricted)
- ❌ Admin Management (restricted)

#### **Super Admin**
- ✅ All Regular Admin features
- ✅ AI Content Generation
- ✅ Content Review & Approval
- ✅ Content Management Hub
- ✅ Admin Management
- ✅ Full system access

### Permission-Based Navigation
- Features are automatically hidden based on your role
- Super Admin sees additional "AI Content", "Review Content", and "Content Hub" options
- Mobile users see a "More" menu for additional features

---

## News Article Management

### Creating News Articles

#### Step 1: Navigate to News Articles
1. Click "News Articles" in the navigation menu
2. Click the "Add Article" button (+ icon)

#### Step 2: Fill Article Details
**Required Fields:**
- **Title**: Compelling headline for the article
- **Description**: Brief summary (appears on cards)
- **Content**: Full article content
- **Category**: Select sport category from dropdown
- **Author**: Select from active admin list
- **Tags**: Add relevant tags (comma-separated)

**Optional Fields:**
- **Image URL**: Featured image for the article
- **Source URL**: Reference link if applicable

#### Step 3: Publishing Options
- **Save to Staging**: Saves article for AI curation before publishing
- **Publish Directly**: Publishes article immediately

### Editing Articles
1. Go to News Articles list
2. Click the edit icon (✏️) next to any article
3. Modify fields as needed
4. Click "Update Article"

### Publishing from Staging
1. Navigate to News Articles
2. Find articles in "Staging" status
3. Click "Publish" button
4. Article undergoes AI curation and automatic notification

### Article Categories
Available sport categories include:
- Football, Cricket, Basketball, Tennis, Badminton
- Swimming, Athletics, Hockey, Volleyball, Kabaddi
- Triple Jump, Soft Tennis, Sepak Takraw, Kho-Kho
- And more...

---

## Sports Wiki Management

### Overview
Sports Wiki allows you to create comprehensive information pages about different sports, complete with images and detailed information.

### Adding a New Sport

#### Step 1: Navigate to Sports Wiki
1. Click "Sports Wiki" in navigation
2. Click "Add Sport" button

#### Step 2: Basic Information
**Required:**
- **Name**: Sport name (e.g., "Cricket")
- **Category**: Sport category
- **Type**: Individual/Team sport

**Optional:**
- **Origin**: Where the sport originated
- **Governing Body**: Official organization
- **Olympic Sport**: Yes/No checkbox

#### Step 3: Detailed Information
- **Description**: Comprehensive overview
- **Rules Summary**: Key rules explanation
- **Famous Athletes**: Notable players (comma-separated)
- **Popular Events**: Major competitions
- **Fun Facts**: Interesting trivia
- **Indian History**: Sport's history in India
- **Regional Popularity**: Popular regions

#### Step 4: Images
Upload up to 3 types of images:
- **Hero Image**: Main sport image
- **Equipment Image**: Sports equipment photo
- **Action Shot**: Sport in action

**Image Requirements:**
- Supported formats: JPG, PNG, WebP
- Maximum size: 5MB per image
- Images are stored in Firebase Storage

#### Step 5: Additional Details
- **Tags**: Searchable keywords
- **Related Sports**: Similar sports
- **Last Updated**: Automatically set

### Editing Sports Entries
1. Find the sport in the list
2. Click edit icon
3. Modify information
4. Images can be updated or removed
5. Click "Update Sport"

### Search and Filtering
- **Search**: Type sport name in search box
- **Filter by Category**: Use category dropdown
- **Filter by Type**: Individual vs Team sports

---

## AI Content Generation
**(Super Admin Only)**

### Overview
AI Content Generation uses OpenAI to create engaging sports content including trivia questions, parent tips, and fun facts.

### Content Types

#### **Trivia Questions**
- Multiple choice questions about sports
- Includes explanations for correct answers
- Difficulty levels: Easy, Medium, Hard
- Perfect for engaging users

#### **Parent Tips**
- Advice for parents about youth sports
- Benefits of playing specific sports
- Age-appropriate recommendations
- Encourages participation

#### **Did You Know Facts**
- Fascinating sports trivia
- Historical facts and records
- Equipment and rule insights
- Celebrity athlete stories

### Generating Content

#### Step 1: Access AI Content
1. Click "AI Content" in navigation (or "More" → "AI Content" on mobile)
2. Ensure you have Super Admin access

#### Step 2: Select Parameters
**Content Type**: Choose from:
- Bulk Trivia (multiple questions)
- Single Parent Tip
- Sport Facts (Did You Know)
- Mixed Content

**Sport Selection**: 
- Choose from available sports in Sports Wiki
- Only sports with wiki entries appear in dropdown

**Quantity**: Number of items to generate (1-10)

**Difficulty**: Easy, Medium, Hard (for trivia)

**Age Group**: Target age range (e.g., "8-16", "All Ages")

**Source Type**:
- **Sports Wiki Only**: Uses your wiki data
- **Online Research**: AI researches online
- **Mixed Sources**: Combines both approaches

#### Step 3: Generate Content
1. Click "Generate Content"
2. Monitor progress in "Active Requests" section
3. Content status updates in real-time
4. Generated content appears in Review screen

### Quick Generation
Use pre-configured cards for common content types:
- **Quick Trivia**: 5 medium difficulty questions
- **Parent Tips**: Single parenting advice
- **Fun Facts**: Interesting sport facts

### Monitoring Generation Requests
- View active requests in progress
- See recent generation history
- Track success/failure status
- Monitor content creation statistics

---

## Content Review & Approval
**(Super Admin Only)**

### Overview
All AI-generated content requires review and approval before publication.

### Review Process

#### Step 1: Access Review Screen
1. Click "Review Content" in navigation
2. View all content with "Generated" status

#### Step 2: Content Preview
For each piece of content, you can:
- **Preview**: See how it will appear to users
- **Edit**: Modify questions, answers, or facts
- **Approve**: Mark as ready for publishing
- **Reject**: Remove from system

#### Step 3: Batch Operations
- Select multiple items using checkboxes
- Use "Bulk Approve" for efficient processing
- Apply filters to focus on specific content types

### Content Filtering
- **Content Type**: Trivia, Parent Tips, Did You Know
- **Sport Category**: Filter by specific sports
- **Search**: Find content by keywords

### Editing Content
1. Click "Edit" on any content item
2. Modify fields as needed:
   - **Trivia**: Question, options, correct answer, explanation
   - **Parent Tips**: Title, benefits, content, age group
   - **Facts**: Fact statement, details, category
3. Save changes
4. Content remains in "Generated" status for further review

---

## Content Management Hub
**(Super Admin Only)**

### Overview
Centralized dashboard for managing all content feeds across the platform.

### Main Features

#### **Statistics Dashboard**
View key metrics:
- Total content count
- Content by status (Generated, Approved, Published, Rejected)
- Content by type (Trivia, Parent Tips, Facts)
- Sport-wise distribution

#### **Content List**
Comprehensive view of all content with:
- Content type and sport category
- Current status
- Creation and modification dates
- Quick action buttons

#### **Filtering Options**
- **Status**: Generated, Approved, Published, Rejected, All
- **Content Type**: Trivia, Parent Tips, Did You Know, All
- **Sport**: Filter by specific sports
- **Search**: Text search across content

### Content Operations

#### **Publishing Workflow**
1. **Generated** → AI creates content
2. **Approved** → Admin reviews and approves
3. **Published** → Available to mobile users

#### **Bulk Operations**
- **Bulk Approve**: Approve multiple items
- **Bulk Publish**: Publish multiple approved items
- **Bulk Delete**: Remove unwanted content

#### **Individual Actions**
- **Preview**: View content as users will see it
- **Edit**: Modify content details
- **Approve/Reject**: Change content status
- **Publish**: Make live for users
- **Delete**: Remove permanently

### Content Statistics
Track performance with detailed analytics:
- Content creation trends
- Approval rates
- Sport-wise content distribution
- Monthly generation statistics

---

## Admin Management
**(Super Admin Only)**

### Creating New Admins
1. Navigate to Admin Management
2. Click "Add Admin"
3. Fill required information:
   - Display Name
   - Email Address
   - Username
   - Temporary Password
   - Role (Admin or Super Admin)
4. Set active status
5. New admin receives login credentials

### Managing Existing Admins
- **Edit Profile**: Update admin information
- **Change Role**: Promote/demote between roles
- **Active/Inactive**: Enable/disable access
- **Reset Password**: Generate new password

### Admin Roles Assignment
- **Admin**: Basic content management
- **Super Admin**: Full system access
- Role changes take effect immediately

---

## Push Notifications

### Automatic Notifications
The system automatically sends push notifications for:

#### **News Articles**
- Triggered when articles are published from staging
- Sent to topic subscribers:
  - `sports_news` (general sports news)
  - `sport_[category]` (specific sport, e.g., `sport_cricket`)

#### **Content Feeds**
- Triggered when content status changes to "Published"
- Sent to multiple topics:
  - `sports_content` (all content subscribers)
  - `sport_[category]` (sport-specific)
  - `content_[type]` (content type specific)

### Notification Format

#### **News Articles**
- Title: "⚽ [Sport]: [Article Title]"
- Body: Article description preview
- Deep link: Opens specific article

#### **Content Feeds**
- **Trivia**: "🧠 [Sport] Trivia!" + question preview
- **Parent Tips**: "👨‍👩‍👧‍👦 [Sport] Parent Tip" + tip title
- **Facts**: "💡 [Sport] Fun Fact" + fact preview

### Notification Topics
Mobile users can subscribe to:
- General sports news and content
- Specific sport categories
- Specific content types
- Custom topic combinations

---

## Responsive Design & Mobile Usage

### Desktop Experience
- Full sidebar navigation
- Expanded forms and tables
- Multi-column layouts
- Larger images and content areas

### Mobile/Tablet Experience
- Bottom navigation bar (max 5 items)
- Collapsed menus and forms
- Single-column layouts
- Touch-optimized buttons and controls

### Navigation Differences

#### **Desktop Navigation**
All features visible in left sidebar:
- Dashboard, News Articles, Sports Wiki
- AI Content, Review Content, Content Hub (Super Admin)
- Admin Management (Super Admin)

#### **Mobile Navigation**
Limited to 5 main items:
- Dashboard, News Articles, Sports Wiki
- More (for Super Admin features)
- Profile/Settings

#### **"More" Menu (Mobile Super Admin)**
Access advanced features:
- AI Content Generation
- Review Content  
- Content Management Hub

### Responsive Features
- **Forms**: Stack vertically on small screens
- **Tables**: Horizontal scroll for data tables
- **Dropdowns**: Compact sizing with ellipsis
- **Dialogs**: Full-screen on mobile
- **Images**: Responsive sizing and loading

---

## Best Practices

### Content Creation
1. **News Articles**:
   - Write compelling, SEO-friendly titles
   - Keep descriptions under 120 characters
   - Use high-quality images
   - Add relevant tags for searchability

2. **Sports Wiki**:
   - Provide comprehensive information
   - Use clear, high-resolution images
   - Keep content factual and up-to-date
   - Include regional and cultural context

3. **AI Content**:
   - Review all generated content before publishing
   - Edit for accuracy and local context
   - Ensure age-appropriate content
   - Maintain consistent tone and style

### Workflow Management
1. **Use Staging**: Always use staging for news articles to benefit from AI curation
2. **Batch Operations**: Use bulk approve/publish for efficiency
3. **Regular Reviews**: Check pending content regularly
4. **Quality Control**: Never publish unreviewed AI content

### Performance Tips
1. **Image Optimization**: Compress images before upload
2. **Batch Processing**: Handle multiple items together
3. **Regular Cleanup**: Remove rejected or outdated content
4. **Monitor Statistics**: Track content performance metrics

---

## Troubleshooting

### Common Issues

#### **Login Problems**
- **Issue**: Can't access admin features
- **Solution**: Verify admin role assignment with Super Admin
- **Check**: Ensure account is marked as "Active"

#### **Content Not Appearing**
- **Issue**: Generated content not showing in review
- **Solution**: Check Firestore indexes are built (may take 5-10 minutes)
- **Verify**: Content status in Firebase console

#### **Image Upload Failures**
- **Issue**: Sports Wiki images not uploading
- **Solution**: Check file size (max 5MB) and format (JPG/PNG/WebP)
- **Verify**: Firebase Storage permissions

#### **AI Generation Errors**
- **Issue**: Content generation failing
- **Solution**: Verify OpenAI API key configuration
- **Check**: Super Admin permissions and authentication

#### **Mobile Display Issues**
- **Issue**: UI overflow or navigation problems
- **Solution**: Use latest browser version and clear cache
- **Alternative**: Use desktop for complex operations

### Error Messages

#### **Permission Errors**
- "Access Denied": Insufficient role permissions
- "Authentication Failed": Login session expired
- "Super Admin Required": Feature restricted to Super Admins

#### **Data Errors**
- "Index Required": Firestore index still building
- "Invalid JSON": AI response formatting issue
- "Upload Failed": File size or format problem

#### **Network Errors**
- "Connection Timeout": Check internet connectivity
- "Function Error": Cloud Function execution issue
- "Storage Error": Firebase Storage access problem

### Getting Help
1. **Check Console**: Browser developer console for detailed errors
2. **Verify Permissions**: Confirm role and active status
3. **Contact Support**: Provide error messages and steps to reproduce
4. **System Status**: Check Firebase console for service status

---

## Technical Architecture

### System Components
- **Frontend**: Flutter Web Application
- **Backend**: Firebase Cloud Functions
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Authentication**: Firebase Auth
- **AI Integration**: OpenAI GPT-4o-mini
- **Push Notifications**: Firebase Cloud Messaging

### Data Collections
- **news_articles**: Published news content
- **news_staging**: Articles awaiting AI curation
- **sports_wiki**: Comprehensive sports information
- **content_feeds**: AI-generated content (trivia, tips, facts)
- **content_generation_requests**: AI generation tracking
- **admins**: Admin user accounts
- **notifications**: Push notification logs

### Security Features
- Role-based access control
- Firebase Authentication integration
- Secure admin verification for AI functions
- Firestore security rules
- Input validation and sanitization

---

## Version History & Updates

### Current Features
- ✅ News Article Management with AI curation
- ✅ Comprehensive Sports Wiki system
- ✅ AI Content Generation (GPT-4o-mini)
- ✅ Content Review & Approval workflow
- ✅ Automatic Push Notifications
- ✅ Mobile-responsive design
- ✅ Role-based access control
- ✅ Image upload and management

### Future Enhancements
- Content scheduling and automation
- Advanced analytics and reporting
- Multi-language support
- Content templates and presets
- Advanced AI customization options

---

*Last Updated: September 2024*  
*Version: 1.0*  
*System: SportEve Admin Portal*

---

## Quick Reference

### Keyboard Shortcuts
- **Ctrl+N**: New article/content
- **Ctrl+S**: Save current form
- **Ctrl+F**: Search/Filter
- **Escape**: Close dialog/modal

### Support Contacts
- **Technical Issues**: Contact system administrator
- **Feature Requests**: Submit through admin dashboard
- **Content Guidelines**: Refer to editorial guidelines
- **Emergency Access**: Contact Super Admin

### Important URLs
- **Admin Portal**: [Your admin portal URL]
- **Firebase Console**: https://console.firebase.google.com
- **System Status**: Check Firebase status page
- **Documentation**: This guide and technical docs
