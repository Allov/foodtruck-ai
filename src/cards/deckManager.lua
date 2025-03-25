local DeckManager = {}

-- Moves all cards from discard pile back to draw pile
function DeckManager.returnDiscardToDraw(deck)
    if not deck then return end

    for _, card in ipairs(deck.discardPile) do
        -- Reset card states before adding back to draw pile
        card:setLocked(false)
        card:setSelected(false)
        table.insert(deck.drawPile, card)
    end
    deck.discardPile = {}
end

-- Shuffles the draw pile
function DeckManager.shuffleDrawPile(deck)
    if not deck then return end

    for i = #deck.drawPile, 2, -1 do
        local j = math.random(i)
        deck.drawPile[i], deck.drawPile[j] = deck.drawPile[j], deck.drawPile[i]
    end
end

-- Resets and shuffles the entire deck
function DeckManager.resetAndShuffle(deck)
    if not deck then return end

    -- First return all cards to draw pile
    DeckManager.returnDiscardToDraw(deck)
    -- Then shuffle
    DeckManager.shuffleDrawPile(deck)
end

-- Gets current counts of cards in different piles
function DeckManager.getCounts(deck)
    if not deck then return { total = 0, draw = 0, discard = 0 } end

    return {
        total = #deck.cards,
        draw = #deck.drawPile,
        discard = #deck.discardPile
    }
end

-- Draws specified number of cards
function DeckManager.drawCards(deck, count)
    if not deck then return {} end

    local drawnCards = {}
    for i = 1, count do
        -- If draw pile is empty, shuffle discard pile back in
        if #deck.drawPile == 0 then
            DeckManager.resetAndShuffle(deck)
            -- If still empty after shuffle, break
            if #deck.drawPile == 0 then break end
        end

        local card = table.remove(deck.drawPile)
        if card then
            card:setLocked(false)
            card:setSelected(false)
            table.insert(drawnCards, card)
        end
    end

    return drawnCards
end

-- Discards a single card
function DeckManager.discardCard(deck, card)
    if not deck or not card then return end

    card:setLocked(false)
    card:setSelected(false)
    table.insert(deck.discardPile, card)
end

-- Discards multiple cards
function DeckManager.discardCards(deck, cards)
    if not deck or not cards then return end

    for _, card in ipairs(cards) do
        DeckManager.discardCard(deck, card)
    end
end

return DeckManager
