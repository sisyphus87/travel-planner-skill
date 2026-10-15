# 个人定制总纲（sisyphus87 版）

本文件是 travel-planner 的个人定制层，来自 2026-10 河南 8 日游 9 轮迭代的实战沉淀。与上游默认行为的差异以此文件与 [meal-recommendations.md](meal-recommendations.md) 为准。

## 一、检索与核查策略（红线）

1. **小红书不可降级。** 各类信息检索和核查都过小红书——尤其是容易忽略的**区间交通**（跨城班车/拼车/景区直通车/文旅专线）；难查到的信息**优先问小红书**（多帖互证往往比网页搜索更接近当下的真实运营状态）。
2. **高德不可降级。** POI 坐标、评分、人均、营业时间、路线实测（driving/walking）必须来自高德；新建 POI 节点先 `maps_text_search` → `maps_search_detail` 拿坐标与评分，跨段路线跑 `maps_direction_*` 实测。
3. **两者任一降级/不可用时：中止并提醒，不要继续。** 不用低质替代（网页摘要、记忆、编造）硬产出——宁可停下让用户恢复能力（如小红书 MCP 服务、高德 MCP），也不交付未经核查的内容。
4. **善用小红书内置 AI（点点）。** 用户习惯自己用小红书 App 左侧栏「点点 AI」做检索合集再对接过来；Agent 应主动建议用户把点点合集作为输入，并在有页面能力时参考点点结果做交叉验证。点点可适当替代直接搜索（省 MCP 调用、降风控压力），但不替代多帖互证。

### 小红书甄别纪律

- 只采含具体时间/价格/流程的实访细节帖；排除无细节营销贴。
- 营销腔信号：通篇夸赞、成语堆砌、评论区空洞（"满分/码住"）、@美食薯、文末带品牌话题。
- **评论区常出关键信息**：差评、避雷、服务态度、更优替代（"不如斜对面那家"）都值得采集进推荐备注。
- 多帖互证才落店；单帖强推但评论区翻车的降级为备选或不采纳。

## 二、双版本交付版式（定调基准，强制）

**每次交付必须同时产出两份**，由同一份 trip.json 生成，各自参照本节规范；只交一份不算完成。两版版式均已由用户定调锁定，**修改前先归档**（`_history/<时间戳>_<轮次>_前/`）。

### 交互版 trip.html（爸妈/本人手机用，可含 JS）

管线：`render_markdown → render_html（assets/template.html）→ 项目层注入（清单/攻略/亮色）→ 校验部署`。

- hero 区：标题 + 日期行；**不放 summary 总览段**（用户 2026-10-13 指示删除）。
- **隐藏「行程信息」悬浮按钮**（`.drawer-toggle`，模板已内置 `button.drawer-toggle{display:none!important}`）——手机端占位置，行程信息由每日清单承载（用户 2026-10-13 指示）。
- 紧随 hero：**每日行动清单**卡片（行前 + D1-Dn，可勾选、localStorage 记忆、进度条）；每张卡含当日关键动作（车次座位/集合点/电话/提醒事项）。
- 各日行程卡内穿插小红书攻略要点（details 折叠）+ 笔记链接 chips。
- 亮色适老化锁定（`color-scheme: light` 强制层），移动端字号 ≥17.5px。
- **交付时必须发布 GitHub Pages**（见下节），返回验证过的公开链接；本地文件与线上链接同回合交付。

### 交互版 GitHub Pages 发布（每次交付必做）

1. 仓库 `sisyphus87/travel-pages`（public，main 分支根目录）；
2. 文件名用**不可猜测的随机 slug**（如 `h8n-<10 位随机>.html`）；同一行程复用首次 slug，后续更新覆盖同一文件（链接不变）；
3. 根目录保留伪装 404 的 `index.html`，不放任何索引列表；
4. **⚠ inline 隐藏规则坑（2026-10-14 实证）**：页面里 inline `<style>` 形式的 `.drawer-toggle{display:none!important}`（含注释版与压缩版两种写法）会导致 Pages 构建 `errored: Page build failed`（无错误细节；同内容去掉该行即 built，站点删建也救不回）。**发布前必须把该规则剥离到外部 `styles.css`**（规则写 `button.drawer-toggle,.drawer,.drawer-backdrop{display:none !important}`）并在 `</head>` 前加 `<link rel="stylesheet" href="styles.css">`；本地自包含版（Downloads 交付）保留模板 inline 行不受影响；
5. 发布步骤（手动配方，不落脚本）：剥离转换 → cp 页面与 styles.css 到仓库 clone → `git -C <dir> commit/push`（注意 Mimosa 拦复合命令，用 `git -C` 独立跑；远端有新提交先 `pull --rebase`——并行会话可能推过）→ 轮询 `gh api repos/sisyphus87/travel-pages/pages/builds` 至 `built`（errored 即中止排查）→ `curl` 200 且字节数与本地一致才算成功；
6. 若连续 errored 且内容无嫌疑：`gh api -X DELETE repos/sisyphus87/travel-pages/pages` 删站重建（`POST /pages` source main /），可修复顽固站点级构建故障；
7. 页面含司机/导游电话、取票号等——随机 URL + 无索引即轻量保护，不额外脱敏（爸妈自用必需）；
8. 建议顺手生成二维码（`qrcode` 库）存 `~/Downloads/<行程名>_二维码.png`。

### 静态展开版 offline_flat.html（父母预览器用，iOS QuickLook 禁 JS）

- **零脚本、零折叠**，单文件；排版锁定为用户 2026-10-10 参考版：暖色卡片、时间线行「时间 + 加粗节点 + 📍导航 + 停留时长 + 备注 + 费用」。
- **每个时间线节点带 📍导航链接**：`https://uri.amap.com/navigation?to={lng},{lat},{quote(名称去状态后缀)}&mode=car&coordinate=gaode&callnative=1`；坐标从 trip.json 全部 POI 自动同步（COORD 表），不手维护。
- 区块只保留：**每日行程 + 预算**；不放「每日速览清单」「预订与办理」（用户 2026-10-13 指示删除）。
- 攻略链接以纯文字链放在日卡尾部。

### 部署位约定

交付到 `~/Downloads/`，文件名以用户既有命名为准（改名前确认）；旧版本归档进项目 `_history/`。

## 三、数据与工程纪律

- **trip.json 是唯一事实源**；两版 HTML 都从它生成，不手改交付物（版式层除外）。
- **断言先行**：批量更新脚本先断言现状（字段匹配、POI 数）再 `json.dump`，任何断言失败立即中止不写盘。
- **改结构前 fresh read**：上下文压缩后回放的旧读取结果 ≠ 文件现状；索引类 mutation 前必须重新读文件（河南项目 D2 事故教训）。
- **火车段表达为车站 POI**（出发/换乘/到达全量入时间线，note 含车次/座位/取票号/检票口），**不写 transports**（校验器 V8 的 source 白名单只收高德源；`next_mode: "train"` 标记即可跳过通勤粗算）。
- **改前必归档**：trip.json + 已部署 HTML 快照进 `_history/`。
- 复合长命令里含 .py 路径会被安全钩子误拦：**JSON 数据修复与管线命令分开跑**。
- 更新轮次命名：一调/二调…依次递增；每轮同步 prebook/budget/清单卡片/XHS 链接，然后 `validate` 0 fail → 全管线 → 部署 → 残留 grep 审计（旧话术清零）→ 记忆沉淀。

## 四、提醒事项的落点

用户要求"设立提醒"的事项（如顺风车前晚预约、导游电话、续订/退订）要同时写进三处：`prebook.deadline`（带 ⏰ 前缀）、当日行动清单卡片的独立条目、`rechecks`（带 `recheck_at`）。

## 五、导航能力基准（2026-10-15 定稿）

- **交互版（模板内置）**：交通段导航链接带 📍 图标；用餐推荐条（meal-leg）的餐厅名旁生成「📍导航」（备选有坐标则「📍备选」），由模板 `mealNavUrl(m)` 用 meals 的 main/alt 坐标生成 `uri.amap.com/navigation?to=…` 单点链接，**无坐标不生成**；店名取「（」「·」前的短名。
- **时段外餐次兜底**：早<11 点/午 11-15 点/晚≥17 点窗口没匹配到的餐次会插入当日最后 POI 卡（`finalPoiItems` 机制）。⚠ 模板维护教训：兜底变量 `timelineItems` **初始必须为 `null` 而非 `''`**（空字符串会让无兜底的天时间线被清空）。
- **静态版（项目层配方）**：生成器读 trip.json meals 坐标建 `MEAL_NAV` 表（短名→坐标），渲染「餐饮」区块行时对行内店名注入 📍 链接——有坐标才加，无坐标纯文字。
- **静态版时间线导航**：坐标表自动扫 trip.json 全部 POI（含状态后缀剥离的短名兜底表），每个时间线节点带 📍导航。

## 六、渲染改动的回归验证法（浏览器实测）

模板/注入层改动不能用 grep 验证（页面 JS 运行时渲染）。标准流程：

1. 项目目录 `python3 -m http.server 8799`，浏览器打开 `http://127.0.0.1:8799/trip.html`；
2. 页面内逐天点击 `.tab`（**先 scrollIntoView 再 click**，Playwright 角色定位会因 tabs 横向滚动超时）；
3. 每天统计回归断言：`.time-block` 节点数 == trip.json 当日 POI 数、`a.meal-nav`/`a.next-leg-nav` 数量、抽查店名解码自 URL；
4. 涉及版式的改动补手机宽度视口（setViewportSize 390×844）目检。

## 七、清单区整体收缩（交互版配方）

每日行动清单区默认收起为一行总开关（标题 + 迷你进度条 + done/total + 箭头），点击/回车展开完整清单，状态 localStorage 记忆（默认收起）；勾选时同步刷新总开关上的进度。目的：手机上快速下翻到行程区。（河南项目 inject_html.py 的 zx-master 实现可作参考模板。）
