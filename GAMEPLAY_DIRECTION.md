# PixelTownGame Gameplay Direction

## Core Fantasy

This prototype should feel like running a small ramen shop in a cherry-blossom onsen town at night.
The focus is not high-pressure cooking. The focus is mood, regulars, night foot traffic, and light but meaningful business decisions.

The player fantasy is:
- read the street before opening
- understand who will come tonight
- serve the right bowls to the right people
- slowly make the street feel more alive because your shop exists

## Prototype Scope

Target a 10 to 12 minute vertical slice built around three nights.

Keep:
- one walkable street
- one enterable ramen shop
- 3 customer types
- 3 ramen dishes
- one nightly revenue goal
- one optional special request per night
- day-end summary and small between-night growth

Cut for now:
- open world expansion
- deep inventory or decoration systems
- complex cooking minigames
- long dialogue trees
- large NPC counts
- save/load and long-term progression

## Core Loop

Each night should have four phases:

1. Street prep, 45 to 60 seconds
   The player walks the street, gets tonight's foot-traffic hint, and accepts one optional request.

2. Shop service, 150 to 180 seconds
   Customers arrive in waves. The player decides who to serve first and which dishes to prioritize.

3. Closing stretch, about 20 seconds
   No new customers arrive. The player resolves remaining orders.

4. Summary
   Show revenue, missed customers, completed requests, and offer one small buff for the next night.

## Street to Shop Loop

The street must stop being a visual lobby and start carrying gameplay information.

Street interaction points:
- ramen shop door: start service
- notice board or inn clerk: tonight's crowd hint
- one or two named NPCs: special customer request or story beat

That information should change shop decisions:
- more bathhouse tourists means more premium bowls
- more office workers means fast cheap bowls matter
- a regular may ask for a specific dish and reward correct service

## Shop Play

Do not keep the current "press E to clear the oldest queue item" structure long-term.
The shop needs light decision pressure without becoming a frantic kitchen simulator.

Recommended interaction flow:
- move to broth station to pick a base bowl
- move to topping station to finish the order
- move to serve point and deliver to a selected customer

Menu roles:
- soy ramen: fast, cheap, stable crowd-control dish
- miso ramen: balanced default dish
- onsen egg ramen: slower, limited, high-profit dish

Customer roles:
- bathhouse traveler: patient, likes premium bowls
- local regular: medium patience, may have special requests
- office worker: low patience, wants fast service

## Three-Night Slice

Night 1:
- teach movement, taking an order, making a bowl, serving

Night 2:
- introduce street hints and one special request

Night 3:
- introduce a real rush wave that forces tradeoffs

## Growth

Use one small between-night pick instead of a full tech tree.

Example upgrades:
- first three bowls cook faster
- extra onsen eggs tonight
- first two customers gain more patience

## Why This Direction

This gives every layer a job:
- the street provides information and anticipation
- the shop provides decisions and pacing
- the nightly structure provides momentum
- the town mood from the reference image becomes actual gameplay, not just decoration
