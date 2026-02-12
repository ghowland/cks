-- columns.lua
function Div(el)
  if el.classes:includes('columns') then
    -- Convert the div to a LaTeX environment for the PDF
    return {
      pandoc.RawBlock('tex', '\\begin{figure}[H]\\centering'),
      el,
      pandoc.RawBlock('tex', '\\end{figure}')
    }
  end
end

function Image(img)
  -- Automatically set a default width for all images if not specified
  if img.attributes['width'] == nil then
    img.attributes['width'] = '80%'
  end
  return img
end
