const express = require('express');
const app = express();
const port = 3000;

app.use(express.static('public'));

app.get('/headers', (req, res) => {
  const forwardedHeaders = Object.fromEntries(
    Object.entries(req.headers).filter(([key]) => key.startsWith('x-'))
  );
  res.json(forwardedHeaders);
});

app.listen(port, () => console.log(`Server running at http://localhost:${port}`));
