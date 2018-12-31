-- Retarget internal links for e-book versions

fromto = {}
fromto["appendices/a-savvy-devs.md"] = "#savvy-devs"
fromto["a-savvy-devs.md"] = "#savvy-devs"
fromto["appendices/b-spm.md"] = "#spm-intro"
fromto["b-spm.md"] = "#spm-intro"
fromto["appendices/c-mysql.md"] = "#mysql-kuery"
fromto["07-kuery.md"] = "#kuery"
fromto["../07-kuery.md"] = "#kuery"
fromto["09-templating.md"] = "#templating"

imgfromto = {}
imgfromto["content/images/cc-badge.png"] = "images/cc-badge.png"

function Link (el)
  if fromto[el.target] then
    el.target = fromto[el.target]
  end
  return el
end

function Image (el)
  if imgfromto[el.src] then
    el.src = imgfromto[el.src]
  end
  return el
end
