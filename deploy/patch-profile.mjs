// 把 dsh-purge 写进指定 profile 的 package.json（只追加两处，不动其它字段）。
// 用法: node patch-profile.mjs <profile-package.json>
import fs from "node:fs";

const p = process.argv[2];
if (!p) {
	console.error("usage: node patch-profile.mjs <path-to-profile-package.json>");
	process.exit(2);
}

const raw = fs.readFileSync(p, "utf8").replace(/^\uFEFF/, "");
const j = JSON.parse(raw);

j.dependencies = j.dependencies && typeof j.dependencies === "object" ? j.dependencies : {};
j.dependencies["dsh-purge"] = "file:../../plugins/dsh-purge";

j.dsh = j.dsh && typeof j.dsh === "object" ? j.dsh : {};
j.dsh.profile = j.dsh.profile && typeof j.dsh.profile === "object" ? j.dsh.profile : {};
const bundles = Array.isArray(j.dsh.profile.bundles) ? j.dsh.profile.bundles : [];
if (!bundles.includes("dsh-purge")) bundles.push("dsh-purge");
j.dsh.profile.bundles = bundles;

// 不写 BOM：安装器 JSON.parse 遇到 BOM 会直接报 Unexpected token ''
fs.writeFileSync(p, JSON.stringify(j, null, 2) + "\n", "utf8");
console.log("patched " + p);
