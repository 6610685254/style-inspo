# Trend & Closet Outfit Suggestion App

An app concept that suggests outfits based on current trends and what a user already owns. The goal is to blend trend insights with a personal closet inventory so recommendations feel fresh, practical, and wearable.

## Core idea
Users catalog what they own (items, colors, fits, occasions). The app pulls trend signals (e.g., trending colors, silhouettes, or patterns) and generates outfit suggestions that:
- Prioritize items the user already owns.
- Fill gaps with optional “wish-list” items that match trends.
- Offer alternatives for weather, occasion, and personal style preferences.

## Key features
- **Closet inventory**: Quick add via tags (type, color, material, season, occasion, formality).
- **Trend engine**: Weekly trend signals for colors, fabrics, and silhouettes.
- **Outfit builder**: Combine tops/bottoms/layers/shoes/accessories into a coherent look.
- **Personalization**: Adjust for climate, comfort, style goals (casual, smart, streetwear, etc.).
- **Explainability**: Show why each recommendation fits trends and the user’s closet.
- **Social layer**: Share outfits, follow friends/creators, and get feedback or reactions.

## Example flow
1. User scans or adds wardrobe items.
2. App fetches trend data (e.g., “earth tones”, “oversized blazers”).
3. App recommends 3–5 outfits using owned items.
4. Optional: suggest 1–2 add-on items that would complete a trend look.

## Data model sketch
- **User**: profile, sizes, style preferences.
- **ClosetItem**: category, color, material, season, formality, images.
- **TrendSignal**: season, category, color palette, score.
- **OutfitRecommendation**: item IDs, score, reasoning.

## Future enhancements
- Outfit scheduling/calendar.
- Social challenges, style boards, and community-curated looks.
- Budget-aware shopping recommendations.
- Sustainability scoring (re-wear rate).
