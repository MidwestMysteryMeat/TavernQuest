# Assets removed — licensing

The card art that lived under this folder is a purchased pack licensed to
the project owner only, so it is **not in the repo**. The game expects the
files at these same paths; fresh clones render fully-functional vector
placeholder cards (suit glyph + rank text) instead. Originals live on the
owner's dev machine. **Never commit media files here.**

Full replacement manifest: see [`ASSETS_NEEDED.md`](../ASSETS_NEEDED.md)
at the repo root.

## What belongs here

52 card faces loaded by `cards.lua` (`Cards.getCardImagePath`):

```
CardsImages/CardDeck/4ColorCards/726X1044/Deck1/
    T_4ColorCards_Deck1_HighRes_<Suit><Rank>_Diffuse.PNG
```

- **Suits:** `Hearts`, `Diamonds`, `Clubs`, `Spades` (wild cards reuse Spades)
- **Ranks:** `2` `3` `4` `5` `6` `7` `8` `9` `10` `J` `Q` `K` `A`
- **Reference format:** PNG, 726x1044 (portrait; scaled to fit at draw time,
  keep roughly 0.7:1 aspect)
- Example: `T_4ColorCards_Deck1_HighRes_HeartsA_Diffuse.PNG`

Everything is optional — poker and all card minigames run on the vector
fallback with no files present.
