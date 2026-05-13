

USE inflacion_mexico;

-- ─── PERIODO (36 meses: ene 2022 – dic 2024) ────────────────
INSERT INTO PERIODO (fecha, anio, mes, quincena, etiqueta) VALUES
('2022-01-01',2022,1,NULL,'2022-01'),('2022-02-01',2022,2,NULL,'2022-02'),
('2022-03-01',2022,3,NULL,'2022-03'),('2022-04-01',2022,4,NULL,'2022-04'),
('2022-05-01',2022,5,NULL,'2022-05'),('2022-06-01',2022,6,NULL,'2022-06'),
('2022-07-01',2022,7,NULL,'2022-07'),('2022-08-01',2022,8,NULL,'2022-08'),
('2022-09-01',2022,9,NULL,'2022-09'),('2022-10-01',2022,10,NULL,'2022-10'),
('2022-11-01',2022,11,NULL,'2022-11'),('2022-12-01',2022,12,NULL,'2022-12'),
('2023-01-01',2023,1,NULL,'2023-01'),('2023-02-01',2023,2,NULL,'2023-02'),
('2023-03-01',2023,3,NULL,'2023-03'),('2023-04-01',2023,4,NULL,'2023-04'),
('2023-05-01',2023,5,NULL,'2023-05'),('2023-06-01',2023,6,NULL,'2023-06'),
('2023-07-01',2023,7,NULL,'2023-07'),('2023-08-01',2023,8,NULL,'2023-08'),
('2023-09-01',2023,9,NULL,'2023-09'),('2023-10-01',2023,10,NULL,'2023-10'),
('2023-11-01',2023,11,NULL,'2023-11'),('2023-12-01',2023,12,NULL,'2023-12'),
('2024-01-01',2024,1,NULL,'2024-01'),('2024-02-01',2024,2,NULL,'2024-02'),
('2024-03-01',2024,3,NULL,'2024-03'),('2024-04-01',2024,4,NULL,'2024-04'),
('2024-05-01',2024,5,NULL,'2024-05'),('2024-06-01',2024,6,NULL,'2024-06'),
('2024-07-01',2024,7,NULL,'2024-07'),('2024-08-01',2024,8,NULL,'2024-08'),
('2024-09-01',2024,9,NULL,'2024-09'),('2024-10-01',2024,10,NULL,'2024-10'),
('2024-11-01',2024,11,NULL,'2024-11'),('2024-12-01',2024,12,NULL,'2024-12');

-- ─── COMPONENTE_PRECIO (8 filas) ────────────────────────────
INSERT INTO COMPONENTE_PRECIO (id_padre,clave,nombre,clasificacion,ponderador_pct,nivel,serie_banxico) VALUES
(NULL,'GENERAL','INPC General','general',100.0000,1,'SP1'),
(1,'SUBYA','Subyacente','subyacente',72.2800,2,'SP74665'),
(1,'NSUBYA','No Subyacente','no_subyacente',27.7200,2,'SP30574'),
(2,'ALIM_PROC','Alimentos procesados, bebidas y tabaco','subyacente',26.0500,3,'SP30577'),
(2,'SERVICIOS','Servicios','subyacente',46.2300,3,'SP30579'),
(3,'AGROPEC','Agropecuarios','no_subyacente',13.8200,3,'SP30585'),
(3,'ENERG','Energéticos y tarifas gobierno','no_subyacente',13.9000,3,'SP30573'),
(2,'VIVIENDA','Vivienda','subyacente',12.9500,3,'SP30580');

-- ─── REGION (5 filas) ────────────────────────────────────────
INSERT INTO REGION (nombre,zona_geografica) VALUES
('Norte','norte'),('Bajío / Centro-Occidente','centro'),
('Centro / Megalópolis','centro'),('Sur','sur'),('Sureste','sureste');

-- ─── CIUDAD (10 filas) ───────────────────────────────────────
INSERT INTO CIUDAD (id_region,nombre,estado,zona_calor_electrico,clave_inegi) VALUES
(1,'Tijuana, B.C.','Baja California',TRUE,'02004'),
(1,'Monterrey, N.L.','Nuevo León',TRUE,'19039'),
(1,'Ciudad Juárez, Chih.','Chihuahua',FALSE,'08037'),
(2,'Guadalajara, Jal.','Jalisco',FALSE,'14039'),
(2,'León, Gto.','Guanajuato',FALSE,'11020'),
(3,'Área Met. Cd. de México','Ciudad de México',FALSE,'09015'),
(3,'Puebla, Pue.','Puebla',FALSE,'21114'),
(4,'Acapulco, Gro.','Guerrero',TRUE,'12001'),
(5,'Mérida, Yuc.','Yucatán',TRUE,'31050'),
(5,'Villahermosa, Tab.','Tabasco',TRUE,'27004');

-- ─── PRODUCTO_CANASTA (10 filas) ────────────────────────────
INSERT INTO PRODUCTO_CANASTA (id_componente,nombre,unidad_medida,es_basico,incluido_pacic,serie_banxico) VALUES
(6,'Jitomate','kg',TRUE,FALSE,'SP30786'),
(6,'Cebolla','kg',TRUE,FALSE,'SP30787'),
(6,'Chile serrano','kg',TRUE,FALSE,'SP30789'),
(6,'Huevo','kg',TRUE,TRUE,'SP30754'),
(6,'Pollo en piezas','kg',TRUE,TRUE,'SP30749'),
(4,'Tortilla de maíz','kg',TRUE,TRUE,'SP30716'),
(4,'Pan blanco','pieza',TRUE,FALSE,'SP30719'),
(4,'Leche pasteurizada','litro',TRUE,TRUE,'SP30736'),
(4,'Aceite vegetal','litro',TRUE,TRUE,'SP30742'),
(5,'Gas L.P. doméstico','servicio',FALSE,FALSE,'SP30810');
