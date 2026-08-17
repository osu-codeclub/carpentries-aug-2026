-- Injects Previous/Next page-nav links (partials/page-nav.html) at the end
-- of each main lesson page, based on its position in this fixed sequence
-- (which mirrors the navbar order in _quarto.yml).

local pages = {
  { href = "0_setup.html",   label = "0: Installation" },
  { href = "1_intro.html",   label = "1: Intro" },
  { href = "2_vectors.html", label = "2: Vectors and Data Types" },
  { href = "3_dplyr.html",   label = "3: Data Wrangling" },
  { href = "4_ggplot.html",  label = "4: Data Visualization" },
  { href = "bonus.html",     label = "Bonus material" },
}

local function escape_replacement(s)
  local escaped = s:gsub("%%", "%%%%")
  return escaped
end

local function fill_block(html, marker, entry, href_key, title_key)
  if entry then
    html = html:gsub("<!%-%-" .. marker .. "%-%->", "")
    html = html:gsub("<!%-%-/" .. marker .. "%-%->", "")
    html = html:gsub(href_key, escape_replacement(entry.href))
    html = html:gsub(title_key, escape_replacement(entry.label))
  else
    html = html:gsub("<!%-%-" .. marker .. "%-%->.-<!%-%-/" .. marker .. "%-%->", "")
  end
  return html
end

function Pandoc(doc)
  local current = PANDOC_STATE.output_file
  if not current then return doc end
  current = pandoc.path.filename(current)

  local idx = nil
  for i, p in ipairs(pages) do
    if p.href == current then
      idx = i
      break
    end
  end
  if not idx then return doc end

  local prev = pages[idx - 1]
  local next_page = pages[idx + 1]
  if not prev and not next_page then return doc end

  local f = io.open("partials/page-nav.html", "r")
  if not f then return doc end
  local template = f:read("*a")
  f:close()

  local html = template
  html = fill_block(html, "PREV", prev, "__PREV_HREF__", "__PREV_TITLE__")
  html = fill_block(html, "NEXT", next_page, "__NEXT_HREF__", "__NEXT_TITLE__")

  -- Appended as a raw block (rather than via quarto.doc.include_text) so it
  -- lands inside <main>, at the end of the article content column, instead
  -- of after the whole #quarto-content grid (main + TOC sidebar).
  doc.blocks:insert(pandoc.RawBlock("html", html))

  return doc
end
