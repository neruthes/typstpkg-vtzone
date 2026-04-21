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


#let vtzone(
  doc,
  x-scale: 100%,
  max-height: auto,
  horizontal: rtl,
  row-gutter: 0.37em,
  col-gutter: 0.5em,
  custom-parbreak: none,
  initial-skip: 0mm,
) = context {
  let actual-max-h = if max-height == auto { 100mm } else { max-height }
  let row-gutter-pt = measure(v(row-gutter)).height

  let get-atoms(it) = {
    if it == [] or it == [ ] { return () }
    if it.func() == linebreak or it.func() == parbreak { return (it.func(),) }
    if it.has("text") {
      let fields = it.fields()
      let _ = fields.remove("text")
      return it.text.clusters().map(c => box(text(..fields, c)))
    }
    if it.has("children") { return it.children.map(get-atoms).flatten() }
    if it.has("body") { return get-atoms(it.body) }
    return (box(it),)
  }

  // Use mutable array for atoms so we can easily prepend/modify
  let atoms = get-atoms(doc)
  let enders = regex("^[.,;:!?，。；：！？、」』）〉】”]$")
  let leaders = regex("^[「『（〈【“]$")

  let get-txt(atom) = {
    if type(atom) == symbol { return str(atom) }
    if type(atom) == content {
      if atom.has("body") {
        let b = atom.body
        if b.has("text") { return b.text }
        if b.has("body") and b.body.has("text") { return b.body.text }
      }
      // Handle the case where the atom itself is a box containing text
      if atom.has("text") { return atom.text }
    }
    ""
  }

  let output-flow = ()
  if initial-skip > 0mm {
    output-flow.push(box(h(initial-skip)))
  }

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

    // 1. Handle explicit breaks
    if atom == linebreak or atom == parbreak {
      if current-col.len() > 0 {
        output-flow.push(box(stack(dir: ttb, spacing: row-gutter, ..current-col)))
        output-flow.push(h(col-gutter, weak: false))
      }
      if atom == parbreak and custom-parbreak != none {
        output-flow.push(box(custom-parbreak))
        output-flow.push(h(col-gutter, weak: false))
      }
      current-col = ()
      i += 1
      continue
    }

    let atom-h = measure(atom).height
    let gap = if current-col.len() > 0 { row-gutter-pt } else { 0pt }

    // 2. Check for Overflow
    if calc-h(current-col) + gap + atom-h > actual-max-h {
      // RULE: If the character that failed to fit is an "Ender",
      // we must pull characters back from current-col to prevent it starting the next line.
      let txt = get-txt(atom)
      if txt.match(enders) != none {
        // Retrospectively pull all consecutive enders + one non-ender base character
        while current-col.len() > 0 {
          let last = current-col.pop()
          atoms.insert(i, last) // Put back into stream
          if get-txt(last).match(enders) == none {
            break // We pulled the base character, stop.
          }
        }
      } else {
        // Normal overflow: Check if current column ends in a "Leader"
        while current-col.len() > 0 and get-txt(current-col.last()).match(leaders) != none {
          let pulled = current-col.pop()
          atoms.insert(i, pulled)
        }
      }

      // Flush the column (unless it became empty from pulling)
      if current-col.len() > 0 {
        output-flow.push(box(stack(dir: ttb, spacing: row-gutter, ..current-col)))
        output-flow.push(h(col-gutter, weak: false))
        current-col = ()
      }
      // We don't increment 'i' here because the failed atom (and pulled ones)
      // are now at the current 'i' position to be re-processed.
      continue
    } else {
      // 3. Fits normally
      current-col.push(atom)
      i += 1
    }
  }

  // Final Flush
  if current-col.len() > 0 {
    output-flow.push(box(stack(dir: ttb, spacing: row-gutter, ..current-col)))
  }

  // Render
  {
    set text(dir: horizontal)
    set par(leading: 0pt, spacing: 0pt)
    output-flow.map(it => box(baseline: 100%, inset: (bottom: 0mm), box(scale(x: x-scale, reflow: true, it)))).join()
  }
}










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


