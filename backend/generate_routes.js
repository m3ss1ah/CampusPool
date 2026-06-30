const fs = require('fs');
const path = require('path');

const modules = ['auth', 'users', 'commutes', 'requests', 'matching', 'chat', 'notifications', 'upload'];
modules.forEach(m => {
  const dir = path.join(__dirname, 'src', 'modules', m);
  fs.mkdirSync(dir, {recursive: true});
  fs.writeFileSync(path.join(dir, `${m}.routes.js`), "const router = require('express').Router();\nmodule.exports = router;");
});
console.log('Routes generated.');
