*** MAECO UNLP ***
** Instrumentos Computacionales
* Opcional B
* Vicente Liut
* 21/4/2026


* Seteo general del workspace
clear all
set more off

* Seteo ruta de carpeta general
cd "C:\Users\Usuario\Desktop\MAECO - UNLP\Programacion\STATA\TPs"

* Macro de carpeta de bases de input
global bases = "bases\"

macro list

* Queda definida la ruta general de trabajo y en especifico la ruta de donde levantar los files de inputs


**# Parte #1

import excel "${bases}comercios.xlsx", clear firstrow

* Ordeno y limpio la base de Excel

rename (ID_comercio Comercio Bandera) (id_comercio comercio bandera)


ssc install labutil // paquete para simplificar la asignacion de labels
labmask id_comercio, values(comercio)

encode bandera, gen(tienda) // variale unica de tienda

* Almaceno la base
tempfile comercios
save "`comercios'", replace


**# Parte #2

use "${bases}precios_01", clear
d

/* Version original
forvalues i = 2/12 {
	if `i' < 10 {
		append using "${bases}precios_0`i'"
	} 
	else append using "${bases}precios_`i'"
}
d
*/ 

* Con ayuda de Gemini:
forvalues i = 2/12 {
    * macro local que siempre tenga 2 dígitos (02, 03, ..., 12)
    local mes : display %02.0f `i'
    
    append using "${bases}precios_`mes'"
}
d

summ


**# Parte #3

* Genero variable de fecha y tomo el mes de ahi
gen fecha = date(mes, "YMD")
gen month = month(fecha)


* Transformo desvio a numerico, forzando NULLs a missing
destring desvio_precio_lista, replace force
drop if desvio_precio_lista == . // descartamos las 14 obs sin valores

gen sucursal_change = (desvio_precio_lista > 0)
tab sucursal_change

* Rename
rename promedio_precio_lista precio


**# Parte #4

collapse (mean) precio (sum) sucursal_change, by(id_comercio id_bandera month)

br
summ precio sucursal_change



**# Parte #5

merge m:1 id_comercio id_bandera using "`comercios'", gen(match_coms)

* solo 63 observaciones con match, en la base de precios hay mas supermercados que los presentes en el catalogo

keep if match_coms == 3 

rename tienda store
	
	
**# Parte #6	

ssc install egenmore // sugerido por Gemini, permite usar el comanto first para armar la base

bysort store (month) : egen base_first = first(precio)

gen precio_index = precio / base_first
label variable precio_index "Precio base primer mes"


**# Parte #7	

* para tener de referencia el mapeo de los labels de store con bandera
tab bandera store , nolab 

* Transformo mediante reshape la base para tener las categorias como lineas individuales

preserve

drop id_comercio id_bandera precio sucursal_change comercio bandera base_first match_coms
reshape wide precio_index, i(month) j(store)

twoway line precio_index* month, ///
	lpattern(solid dash shortdash solid solid dash shortdash) ///
	lc(green green green orange blue blue blue) ///
	title("Evolución del precio de la Coca-Cola por tienda") ///
	subtitle("Base primer mes disponible", size(small) color(gray)) ///
	legend(order(	1 "Carrefour Express" ///
					2 "Carrefour Hiper" ///
					3 "Carrefour Market" ///
					4 "Coto" ///
					5 "Disco" ///
					6 "Jumbo" ///
					7 "Vea") ///
			pos(6) rows(2) region(ls(none)) size(*0.8) symxsize(*0.5)) ///
	ytitle("Indice (base primer mes)", size(small)) ///
	xtitle("Mes", size(small)) ///
	ylabel(1(0.1)1.6, format(%9.1fc) labsize(small) grid gstyle(dot) glc(grey)) ///
	xlabel(#12, format(%9.0fc) labsize(small) grid gstyle(dot) glc(grey)) ///
	scheme(s1color) ///
	graphregion(color(white)) ///
	plotregion(color(white) lcolor(black) lwidth(medium))

graph export "graph_base1.png", replace

restore


**# Parte #8

by store : egen base_agosto = max(cond(month==8, precio, .))

replace precio_index = precio / base_agosto
label variable precio_index "Precio base agosto 2024"


**# Parte #9

preserve

drop id_comercio id_bandera precio sucursal_change comercio bandera base_first match_coms base_agosto
reshape wide precio_index, i(month) j(store)

twoway line precio_index* month, ///
	yline(1, lp(shortdash) lc(gray)) ///
	lp(solid dash shortdash solid solid dash shortdash) ///
	lc(green green green orange blue blue blue) ///
	title("Evolución del precio de la Coca-Cola por tienda") ///
	subtitle("Base agosto 2024", size(small) color(gray)) ///
	legend(order(	1 "Carrefour Express" ///
					2 "Carrefour Hiper" ///
					3 "Carrefour Market" ///
					4 "Coto" ///
					5 "Disco" ///
					6 "Jumbo" ///
					7 "Vea") ///
			pos(6) rows(2) region(ls(none)) size(*0.8) symxsize(*0.5)) ///
	ytitle("Indice (base agosto 2024)", size(small)) ///
	xtitle("Mes", size(small)) ///
	ylabel(0.6(0.1)1.3, format(%9.1fc) labsize(small) grid gstyle(dot) glc(grey)) ///
	xlabel(#12, format(%9.0fc) labsize(small) grid gstyle(dot) glc(grey)) ///
	scheme(s1color) ///
	graphregion(color(white)) ///
	plotregion(color(white) lcolor(black) lwidth(medium))

graph export "graph_base_ago.png", replace

restore

**# Parte #10

summ precio if month >= 8
local precio_prom = r(mean)

graph box precio if month >= 8, over(store, label(labsize(small) angle(30))) ///
	yline(`precio_prom', lcolor(cranberry) lpattern(dash)) ///
	text(`precio_prom' 2 "Promedio", placement(s) color(cranberry) size(vsmall)) ///
	title("Comparación de precio de la Coca-Cola entre tiendas") ///
	subtitle("Agosto-Diciembre 2024", size(small) color(gray)) ///
	asyvars ///
	box(1,color(green)) box(2,color(green)) box(3,color(green)) ///
	box(4,color(orange)) ///
	box(5,color(blue)) box(6,color(blue)) box(7,color(blue)) ///
	showyvars leg(off) ///
	scheme(s1color) ///
	graphregion(color(white)) ///
	plotregion(color(white) lcolor(black) lwidth(medium))
	