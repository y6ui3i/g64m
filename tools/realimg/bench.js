const k = +(process.argv[2] || 1);
function fib(n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }
fib(22 + k);
const s = []; for (let i = 0; i < 40000 * k; i++) s.push(String(i).repeat(3));
s.join(",").split(",");
const d = []; for (let i = 0; i < 4000 * k; i++) d.push({a: i, b: [i, i * 2], c: "x".repeat(10)});
for (let j = 0; j < 5; j++) JSON.parse(JSON.stringify(d));
Array.from({length: 60000 * k}, (_, i) => i).sort((x, y) => (x * 7919) % 10007 - (y * 7919) % 10007);
require("crypto").createHash("sha256").update("x".repeat(4000000 * k)).digest("hex");
console.log("ok");
