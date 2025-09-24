# Sports Wiki Collection Data Structure

This document provides the complete structure for the `sports_wiki` collection in Firestore. Use this guide to add comprehensive sports information to the database.

## 📋 Field Overview

### Required Fields ⭐
- `name` - Sport name (e.g., "Cricket", "Basketball")
- `category` - Team/Individual/Mixed
- `type` - Outdoor/Indoor/Water
- `description` - Basic sport description (2-3 sentences)

### Optional Fields 🔧
All other fields are optional but highly recommended for rich content.

---

## 🏗️ Complete Field Structure

### Basic Information
```json
{
  "name": "string - Sport name",
  "category": "Team | Individual | Mixed",
  "type": "Outdoor | Indoor | Water",
  "description": "string - 2-3 sentence description"
}
```

### Sport Details
```json
{
  "origin": "string - Country/region where sport originated",
  "governing_body": "string - International governing organization",
  "olympic_sport": "boolean - true if Olympic sport",
  "rules_summary": "string - Brief rules explanation (3-4 sentences)",
  "player_count": "string - Number of players (e.g., '11 vs 11', '1 vs 1')",
  "difficulty_level": "Beginner | Intermediate | Advanced | Expert",
  "seasonal_play": "Year-round | Summer | Winter | Spring | Monsoon"
}
```

### Lists (Arrays)
```json
{
  "famous_athletes": ["string", "string"] - 3-5 well-known athletes,
  "popular_events": ["string", "string"] - Major tournaments/competitions,
  "equipment_needed": ["string", "string"] - Required equipment list,
  "physical_demands": ["string", "string"] - Fitness requirements (e.g., "Endurance", "Strength"),
  "fun_facts": ["string", "string"] - Interesting trivia (3-5 facts),
  "tags": ["string", "string"] - Search tags (e.g., "ball-sport", "team-sport"),
  "related_sports": ["string", "string"] - Similar sports
}
```

### Images (Object)
```json
{
  "images": {
    "hero": "string - Main sport image URL",
    "equipment": "string - Equipment image URL",
    "action": "string - Action shot URL",
    "field": "string - Playing field/court image URL"
  }
}
```

### Indian Context (Special Focus) 🇮🇳
```json
{
  "indian_history": {
    "introduction_year": "string - When introduced to India",
    "key_developments": "string - Major developments in India",
    "governing_body_india": "string - Indian governing organization"
  },
  "indian_milestones": ["string", "string"] - Major achievements by Indians,
  "regional_popularity": "string - Which regions/states it's popular in",
  "iconic_moments": "string - Famous moments in Indian sport history"
}
```

---

## 📝 Data Entry Template

Copy this template for each sport:

```json
{
  "name": "",
  "category": "",
  "type": "",
  "description": "",
  
  "origin": "",
  "governing_body": "",
  "olympic_sport": null,
  "rules_summary": "",
  "player_count": "",
  "difficulty_level": "",
  "seasonal_play": "",
  
  "famous_athletes": [],
  "popular_events": [],
  "equipment_needed": [],
  "physical_demands": [],
  "fun_facts": [],
  "tags": [],
  "related_sports": [],
  
  "images": {
    "hero": "",
    "equipment": "",
    "action": "",
    "field": ""
  },
  
  "indian_history": {
    "introduction_year": "",
    "key_developments": "",
    "governing_body_india": ""
  },
  "indian_milestones": [],
  "regional_popularity": "",
  "iconic_moments": ""
}
```

---

## 🎯 Example Entry: Cricket

```json
{
  "name": "Cricket",
  "category": "Team",
  "type": "Outdoor",
  "description": "Cricket is a bat-and-ball game played between two teams of eleven players. It involves hitting a ball with a bat to score runs while the opposing team tries to prevent runs and dismiss the batsmen.",
  
  "origin": "England",
  "governing_body": "International Cricket Council (ICC)",
  "olympic_sport": false,
  "rules_summary": "Two teams take turns batting and bowling. The batting team tries to score runs by hitting the ball and running between wickets. The bowling team tries to dismiss batsmen and limit runs. The team with the most runs wins.",
  "player_count": "11 vs 11",
  "difficulty_level": "Intermediate",
  "seasonal_play": "Year-round",
  
  "famous_athletes": [
    "Virat Kohli",
    "MS Dhoni", 
    "Sachin Tendulkar",
    "Steve Smith",
    "Joe Root"
  ],
  "popular_events": [
    "ICC Cricket World Cup",
    "ICC T20 World Cup", 
    "The Ashes",
    "Indian Premier League (IPL)",
    "ICC Champions Trophy"
  ],
  "equipment_needed": [
    "Cricket bat",
    "Cricket ball",
    "Wickets (stumps)",
    "Protective gear (pads, helmet, gloves)",
    "Cricket whites/colored clothing"
  ],
  "physical_demands": [
    "Hand-eye coordination",
    "Endurance",
    "Quick reflexes",
    "Mental focus",
    "Strategic thinking"
  ],
  "fun_facts": [
    "A cricket match can last up to 5 days in Test format",
    "The fastest recorded cricket ball was bowled at 161.3 km/h",
    "Cricket is the second most popular sport globally",
    "The longest cricket match lasted 14 days",
    "Cricket was played at the Olympics only once in 1900"
  ],
  "tags": [
    "ball-sport",
    "team-sport", 
    "bat-sport",
    "strategic",
    "traditional"
  ],
  "related_sports": [
    "Baseball",
    "Rounders",
    "Softball"
  ],
  
  "images": {
    "hero": "https://example.com/cricket-hero.jpg",
    "equipment": "https://example.com/cricket-equipment.jpg", 
    "action": "https://example.com/cricket-action.jpg",
    "field": "https://example.com/cricket-field.jpg"
  },
  
  "indian_history": {
    "introduction_year": "1700s",
    "key_developments": "Introduced by British colonial officers. India's first cricket club was formed in 1792. Post-independence, cricket became the nation's most popular sport.",
    "governing_body_india": "Board of Control for Cricket in India (BCCI)"
  },
  "indian_milestones": [
    "1983 - First Cricket World Cup win",
    "2007 - T20 World Cup champions", 
    "2011 - Cricket World Cup win at home",
    "2013 - ICC Champions Trophy win",
    "Sachin Tendulkar becomes first to score 100 international centuries"
  ],
  "regional_popularity": "Extremely popular nationwide, especially in Maharashtra, Mumbai, Delhi, Karnataka, Tamil Nadu, and West Bengal",
  "iconic_moments": "1983 World Cup victory at Lord's, 2011 World Cup final six by MS Dhoni, Kapil Dev's 175* in 1983, India's first Test series win in Australia (2018-19)"
}
```

---

## 🎨 Field Value Guidelines

### Categories
- **Team**: Sports requiring multiple players per team (Cricket, Football, Basketball)
- **Individual**: One-on-one or solo sports (Tennis, Chess, Athletics)
- **Mixed**: Can be played individually or in teams (Badminton, Table Tennis)

### Types
- **Outdoor**: Primarily played outside (Cricket, Football, Athletics)
- **Indoor**: Played in enclosed spaces (Basketball, Table Tennis, Chess)
- **Water**: Water-based sports (Swimming, Water Polo, Sailing)

### Difficulty Levels
- **Beginner**: Easy to learn, minimal equipment
- **Intermediate**: Moderate skill required, some specialized equipment
- **Advanced**: High skill level, significant training needed
- **Expert**: Professional level, extensive training and equipment

### Physical Demands (Common Values)
- Endurance, Strength, Speed, Agility, Flexibility, Balance, Coordination, Mental focus, Strategic thinking, Quick reflexes

### Tags (Common Values)
- ball-sport, team-sport, individual-sport, contact-sport, non-contact, indoor, outdoor, water-sport, racquet-sport, combat-sport, precision-sport, endurance-sport

---

## 🚀 For AI Tools

**Prompt Template for AI:**
```
Generate sports wiki data for [SPORT NAME] using this exact JSON structure:

[PASTE THE DATA ENTRY TEMPLATE HERE]

Focus on:
1. Accurate, concise descriptions (2-3 sentences for description, 3-4 for rules)
2. Include 3-5 items in each array field
3. Emphasize Indian context and achievements
4. Use proper categories: Team/Individual/Mixed
5. Use proper types: Outdoor/Indoor/Water
6. Include realistic difficulty levels
7. Add relevant tags for search functionality

Make it informative yet concise, suitable for a sports information app.
```

---

## 📤 Submission Format

Save each sport as a separate JSON file named: `[sport-name].json`

Example: `cricket.json`, `basketball.json`, `chess.json`

This makes it easy to review and import each sport individually into Firestore.

---

*This structure ensures comprehensive, searchable, and engaging sports content for the SportEve app! 🏆*
