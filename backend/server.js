const express = require('express');
const sql = require('mssql');
const app = express();
const port = 4836;

const config = {
  user: 'ServiceMET',
  password: '2025',
  server: 'SERVIDOR-METRICA/SQLEXPRESS',
  database: 'DataMET',
  options: {
    encrypt: true,
    trustServerCertificate: true
  }
};

sql.connect(config, err => {
  if (err) {
    console.error('Error al conectar a la base de datos:', err);
    return;
  }
  console.log('Servidor Conectado a la base de datos');
});

app.get('/data_clientes', (req, res) => {
  const request = new sql.Request();
  request.query('SELECT codigo_cliente, cliente, cliente_id, razonsocial  FROM DATA_CLIENTES', (err, result) => {
    if (err) {
      console.error('Error executing query:', err);
      res.status(500).send('Server error');
      return;
    }
    res.send(result.recordset);
  });
});

app.get('/data_plantas', (req, res) => {
  const request = new sql.Request();
  request.query('SELECT cliente_id, codigo_planta, planta_id, dep, dep_id, planta, dir FROM DATA_PLANTAS', (err, result) => {
    if (err) {
      console.error('Error executing query:', err);
      res.status(500).send('Server error');
      return;
    }
    res.send(result.recordset);
  });
});

app.get('/DATA_EQUIPOS_BALANZAS', (req, res) => {
  const request = new sql.Request();
  const query = 'SELECT * FROM DATA_EQUIPOS_BALANZAS';
  request.query(query, (err, result) => {
    if (err) {
      console.error('Error ejecutando consulta:', err);
      res.status(500).send('Error del servidor');
      return;
    }
    res.send(result.recordset);
  });
});

app.get('/DATA_INSTRUMENTOS_CAL', (req, res) => {
  const request = new sql.Request();
  const query = 'SELECT * FROM DATA_INSTRUMENTOS_CAL';
  request.query(query, (err, result) => {
    if (err) {
      console.error('Error ejecutando consulta:', err);
      res.status(500).send('Error del servidor');
      return;
    }
    res.send(result.recordset);
  });
});

app.get('/DATA_EQUIPOS_CERT', (req, res) => {
  const request = new sql.Request();
  const query = 'SELECT * FROM DATA_EQUIPOS_CERT';
  request.query(query, (err, result) => {
    if (err) {
      console.error('Error ejecutando consulta:', err);
      res.status(500).send('Error del servidor');
      return;
    }
    res.send(result.recordset);
  });
});

app.get('/DATA_SERVICIOS_LEC', (req, res) => {
  const request = new sql.Request();
  const query = 'SELECT * FROM DATA_SERVICIOS_LEC';
  request.query(query, (err, result) => {
    if (err) {
      console.error('Error ejecutando consulta:', err);
      res.status(500).send('Error del servidor');
      return;
    }
    res.send(result.recordset);
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Servidor ejecutándose en http://0.0.0.0:${port}`);
});