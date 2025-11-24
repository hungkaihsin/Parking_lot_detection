# GoPark Demo Script (2-3 Minutes)

**Presenter:** Franco
**Audience:** Project Stakeholders

---

### Introduction (0:00-0:20)

**(Scene: Start with a wide shot of the GoPark app's main map view on an iPhone.)**

**Franco:** "Good morning, everyone. Today, we're demonstrating GoPark, our smart parking solution designed to eliminate the frustration of finding a parking spot. GoPark doesn't just show you what's free; it guides you to the *best* available spot for *you*."

**(Action: Show the app loading and displaying the parking lot.)**

**Franco:** "As you can see, our app displays a real-time map of the parking lot. Green spots are free, red spots are taken. This live data is powered by our vision system, which constantly monitors the lot."

`[GIF of the map with a few spots changing from red to green and vice-versa]`

**Behind the Scenes (cURL):**
```bash
# API call to get live stall status
curl -X POST http://127.0.0.1:8000/lots/main_lot/predict -F 'file=@/path/to/live_frame.jpg'
```

---

### Personalization (0:20-0:50)

**(Scene: User taps on the menu and navigates to the 'My Profile' screen.)**

**Franco:** "But where GoPark truly shines is in its personalization. Let's say I drive a large SUV. Finding a spot that fits can be a challenge. In the profile section, I can save my vehicle information."

**(Action: User selects 'SUV' from a picker and saves their profile.)**

`[Screenshot of the 'My Profile' screen with 'SUV' selected.]`

**Franco:** "By telling GoPark I have an SUV, the recommender system can now filter out compact spots that I won't fit into, ensuring I only get relevant suggestions."

---

### Natural Language Recommendation (0:50-1:40)

**(Scene: User navigates to the 'AI Assistant' chat view.)**

**Franco:** "Now for the magic. Instead of manually searching, I can simply ask our AI assistant for what I need. It's late, and I'm carrying heavy bags, so I want a spot close to the entrance."

**(Action: User types the query "I need a spot for my SUV, preferably close to the entrance" into the chat and sends it.)**

`[GIF of the user typing the query and the AI responding "I've found the perfect spot for you!"]`

**Franco:** "Our natural language processing model understands the user's intent—they need a spot for an 'SUV' and want it 'close to the entrance'."

**Behind the Scenes (cURL):**
```bash
# API call for a natural language recommendation
curl -X POST http://127.0.0.1:8000/recommend -H "Content-Type: application/json" -d '{
  "query": "I need a spot for my SUV, preferably close to the entrance"
}'
```

---

### The Perfect Spot (1:40-2:10)

**(Scene: The app automatically navigates back to the map view. One of the green spots is now highlighted in bright yellow.)**

**Franco:** "And here's the result. The app has highlighted the best available spot in yellow. It's a full-sized spot, close to the main entrance, and it's even a 'buffered' spot with empty spaces on both sides, making it easier to park."

`[Screenshot of the map with the recommended stall 'C-12' highlighted in yellow, with badges for "Buffered" and "Full-Size" visible.]`

**Behind the Scenes (Response JSON):**
```json
{
  "recommendations": [
    {
      "stall_id": "C-12",
      "score": 0.95,
      "reasons": ["Close to entrance", "Good size match", "Buffered spot"],
      "badges": ["Near Entrance", "Buffered"]
    }
  ]
}
```

---

### Conclusion (2:10-2:30)

**(Scene: Zoom out to show the full app interface again.)**

**Franco:** "So in just a few seconds, GoPark took me from a vague need to a precise, actionable recommendation. It's faster, smarter, and less stressful."

**Franco:** "This combination of live vision, personalization, and natural language understanding makes GoPark a truly next-generation parking experience. Thank you."
