# SportEve Admin Portal - Quick Reference

## Login & Roles
- **Regular Admin**: News Articles + Sports Wiki
- **Super Admin**: All features including AI Content, Review, Management

## News Articles Workflow
1. **Create** → Fill form → **Save to Staging**
2. **Staging** → AI Curation → **Auto-publish** 
3. **Published** → Automatic push notifications sent

## Sports Wiki
- **Add Sport** → Fill details + Upload images → **Save**
- **Images**: Hero, Equipment, Action shots (max 5MB each)
- **Required**: Name, Category, Type

## AI Content Generation (Super Admin)
1. **AI Content** → Select type/sport/quantity → **Generate**
2. **Types**: Trivia, Parent Tips, Did You Know
3. **Sources**: Sports Wiki, Online Research, Mixed

## Content Review (Super Admin)
1. **Review Content** → See AI-generated items
2. **Actions**: Preview, Edit, Approve, Reject
3. **Bulk Operations**: Select multiple → Bulk Approve

## Content Publishing (Super Admin)
1. **Content Hub** → Filter "Approved" status
2. **Publish** → Content goes live + Push notifications sent
3. **Bulk Publish**: Select multiple → Publish all

## Push Notifications (Automatic)
- **News**: Published articles → `sports_news` + `sport_[category]`
- **Content**: Published feeds → `sports_content` + `content_[type]`

## Mobile Navigation
- **Desktop**: Full sidebar with all features
- **Mobile**: Bottom nav (5 items max) + "More" menu for Super Admin

## Quick Actions
| Feature | Regular Admin | Super Admin |
|---------|---------------|-------------|
| News Articles | ✅ Full Access | ✅ Full Access |
| Sports Wiki | ✅ Full Access | ✅ Full Access |
| AI Generation | ❌ No Access | ✅ Full Access |
| Content Review | ❌ No Access | ✅ Full Access |
| Content Hub | ❌ No Access | ✅ Full Access |
| Admin Management | ❌ No Access | ✅ Full Access |

## Common Workflows

### Creating News Article
```
News Articles → Add Article → Fill Form → Save to Staging → Auto-publish
```

### AI Content Creation
```
AI Content → Select Parameters → Generate → Review Content → Approve → Content Hub → Publish
```

### Adding Sport Info  
```
Sports Wiki → Add Sport → Fill Details → Upload Images → Save
```

## Error Troubleshooting
- **Index Error**: Wait 5-10 minutes for Firestore indexes to build
- **Permission Error**: Check admin role assignment
- **Upload Error**: Verify file size (max 5MB) and format (JPG/PNG/WebP)
- **AI Error**: Verify Super Admin access and OpenAI configuration

## Support
- Check browser console for detailed errors
- Verify admin role and active status
- Contact Super Admin for permission issues

*Quick Reference v1.0 - September 2024*
