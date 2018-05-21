-- Retarget internal links for e-book versions

fromto = {}
fromto["appendices/a-savvy-devs.md"] = "#savvy-devs"
fromto["a-savvy-devs.md"] = "#savvy-devs"
fromto["appendices/b-spm.md"] = "#spm-intro"
fromto["b-spm.md"] = "#spm-intro"
fromto["appendices/c-mysql.md"] = "#mysql-kuery"
fromto["5-kuery.md"] = "#kuery"
fromto["../5-kuery.md"] = "#kuery"

function Link (el)
  if fromto[el.target] then
    el.target = fromto[el.target]
  end
  return el
end
