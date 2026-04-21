#import "../src/vtzone.typ": *


#show: fix-cjk-punct-vertical

#set page(margin: 30mm, )
#set text(font: ("Noto Serif CJK SC", "MiSans"), size: 12pt, dir: rtl)



#page[
  #set align(center)
  // #set text(size: 52pt)
  #set text(size: 22pt, font: ("TeX Gyre Termes", "Noto Serif CJK SC"))
  #v(30mm)

  Demo doc for\ the
  `vtzone`
  package

  #v(20mm)
  #set text(size: 18pt)

  using classic text \
  三国演义

  #v(1fr)
  #set text(size: 12pt)
  https://github.com/neruthes/typstpkg-vtzone
]


#let maketitle(chapid, chapname) = [

  #let out1 = box(vtzone(
    max-height: 220mm,
  )[第#chapid;回 #parbreak() #chapname])
  #place(top + right, {
    set text(size: 22pt)
    set align(center)
    out1
  })
]


// #show regex("\p{Han}"): "傳" // Debugging








#let mkchapcontent(chapdata) = context vtzone(
  x-scale: 110%,
  row-gutter: 0.42em,
  col-gutter: 0.45em,
  max-height: page.height
    - if type(page.margin) == dictionary { page.margin.top + page.margin.bottom } else { 2 * page.margin }
    - 2.5 * text.size,
  // initial-skip: 30mm,
  custom-parbreak: h(9pt),
  chapdata,
)

#show "“": "「"
#show "”": "」"
/*
for txt in demo/d*.txt; do
  sed -i 's/“/「/g' "$txt"
  sed -i 's/”/」/g' "$txt"
done
*/


#set page(margin: 18mm, footer: { context counter(page).display() })

// #let mkchap(chapid, chapname) = {
//   maketitle(chapid, chapname)
//   mkchapcontent[ #include "d@.txt".replace("@", chapid) ]
//   pagebreak(weak: true)
// }
#let mkchap(chapid, chapname) = {
  mkchapcontent[
    #text(size: 18pt, weight: 600)[第　#chapid;　回 #parbreak() #chapname]
    #parbreak()
    ~~ #parbreak()
    ~~ #parbreak()
    ~~ #parbreak()
    #include "d@.txt".replace("@", chapid)
  ]
  pagebreak(weak: true)
}

#mkchap("001", [宴桃园豪杰三结义　斩黄巾英雄首立功])
#mkchap("002", [张翼德怒鞭督邮　何国舅谋诛宦竖])
#mkchap("003", [议温明董卓叱丁原　馈金珠李肃说吕布])
