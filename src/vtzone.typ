// =======================================================================
//
// Git repository:
//      https://github.com/neruthes/typstpkg-vtzone
//
//
// Copyright (c) 2026 Neruthes.
// Published with the MIT license.
//
// =======================================================================







#let fix-cjk-punct-vertical(doc) = {
  let movepunctloc(it) = box(stroke: 0.0pt + gray, {
    place(center + horizon, dx: 0.20em, dy: -0.4em, it)
    hide(text(fill: red.transparentize(10%), it))
  })
  show regex("[，。、]"): movepunctloc
  show regex("[？！：；，。、]"): it => align(center, box(width: 1em, it))
  show regex("[「」]"): it => box({
    let that = rotate(-90deg, reflow: true, it)
    let boxS = place(horizon + center, dx: -0.29em, dy: -0.5em, box(fill: none, that))
    let boxE = place(horizon + center, dx: 0.0em, dy: 0.4em, box(fill: none, that))
    (if it.text == "「" { boxS } else { boxE })
    hide(text(fill: red.transparentize(10%), it))
  })
  doc
}







#let vtzone(
  doc,
  x-scale: 100%,
  max-height: auto,
  horizontal: rtl,
  row-gutter: 0.37em,
  col-gutter: 0.5em,
  custom-parbreak: none,
  initial-skip: 0mm,
  inner-alignment: center,
) = context {
  let actual-max-h = if max-height == auto { 100mm } else { max-height }
  let row-gutter-pt = measure(v(row-gutter)).height
  
  let get-atoms(it, wrapper: x => x) = {
    if it == [] or it == [ ] { return () }
    let func = it.func()
    
    // 1. Handle Explicit Breaks
    if func == linebreak or func == parbreak { return (func,) }
    
    // 2. Handle Text Leaves
    if it.has("text") {
      let fields = it.fields()
      let txt = fields.remove("text")
      let text-wrapper = child => wrapper(text(..fields, child))
      return txt.clusters().map(c => box(text-wrapper(c)))
    }
    
    // 3. Handle Sequences (common in parsed trees)
    if it.has("children") {
      return it.children.map(c => get-atoms(c, wrapper: wrapper)).flatten()
    }
    
    // 4. Handle Styled Elements & Containers
    // We must reconstruct the container for each leaf cluster.
    let container-wrapper = child => {
      // If it is a 'styled' element, we wrap the child in the same styled block
      if it.has("styles") and it.has("child") {
        return wrapper(it.func()(child, it.styles))
      }
      
      // For standard functions (strong, emph, rotate, etc.)
      let fields = it.fields()
      let clean-fields = (:)
      let forbidden = ("body", "child", "children", "styles", "text")
      for (k, v) in fields {
        if k not in forbidden { clean-fields.insert(k, v) }
      }
      
      wrapper(it.func()(..clean-fields, child))
    }
    
    // Recurse into the primary content holder
    if it.has("body") {
      return get-atoms(it.body, wrapper: container-wrapper)
    }
    if it.has("child") {
      return get-atoms(it.child, wrapper: container-wrapper)
    }
    
    // Fallback
    return (box(wrapper(it)),)
  }
  
  let atoms = get-atoms(doc)
  let enders = regex("^[.,;:!?，。；：！？、」』）〉】”]$")
  let leaders = regex("^[「『（〈【“]$")
  
  let get-txt(atom) = {
    if type(atom) == symbol { return str(atom) }
    if type(atom) == content {
      if atom.has("text") { return atom.text }
      if atom.has("body") { return get-txt(atom.body) }
      if atom.has("child") { return get-txt(atom.child) }
    }
    ""
  }
  
  let output-flow = ()
  if initial-skip > 0mm { output-flow.push(box(h(initial-skip))) }
  let current-col = ()
  let i = 0
  
  let calc-h(atom_list) = {
    if atom_list.len() == 0 { return 0pt }
    let h_sum = atom_list.map(a => measure(a).height).sum()
    let g_sum = (atom_list.len() - 1) * row-gutter-pt
    h_sum + g_sum
  }
  
  while i < atoms.len() {
    let atom = atoms.at(i)
    if atom == linebreak or atom == parbreak {
      if current-col.len() > 0 {
        output-flow.push(box(stack(dir: ttb, spacing: row-gutter, ..current-col)))
        output-flow.push(h(col-gutter, weak: false))
      }
      current-col = ()
      i += 1
      continue
    }
    
    let atom-h = measure(atom).height
    let gap = if current-col.len() > 0 { row-gutter-pt } else { 0pt }
    
    if calc-h(current-col) + gap + atom-h > actual-max-h {
      let txt = get-txt(atom)
      if txt.match(enders) != none {
        while current-col.len() > 0 {
          let last = current-col.pop()
          atoms.insert(i, last)
          if get-txt(last).match(enders) == none { break }
        }
      } else {
        while current-col.len() > 0 and get-txt(current-col.last()).match(leaders) != none {
          let pulled = current-col.pop()
          atoms.insert(i, pulled)
        }
      }
      if current-col.len() > 0 {
        output-flow.push(box(stack(dir: ttb, spacing: row-gutter, ..current-col)))
        output-flow.push(h(col-gutter, weak: false))
        current-col = ()
      }
      continue
    } else {
      current-col.push(atom)
      i += 1
    }
  }
  
  if current-col.len() > 0 {
    output-flow.push(box(stack(dir: ttb, spacing: row-gutter, ..current-col)))
  }
  
  {
    set text(dir: horizontal)
    set par(leading: 0pt, spacing: 0pt)
    output-flow
      .map(it => {
        box(baseline: 100%, box(scale(x: x-scale, reflow: true, align(inner-alignment, (it)))))
      })
      .join()
  }
}

