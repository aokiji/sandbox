var express = require('express');
var bodyParser = require('body-parser');
var app = express();

app.use(bodyParser.urlencoded({ extended: true }));

// expects license, and seats distribution as array
app.post('/vehicles', function (req, res) {
  data = req.body
  data.seats = eval(data.seats)
  data.id = 1
  res.json(data);
});

app.listen(3000);
