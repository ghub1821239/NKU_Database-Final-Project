const state = {
  me: null,
  pets: [],
  foodStore: [],
  medicineStore: [],
  plans: [],
  foods: [],
  medicines: [],
  selectedPetId: null,
};

const loginView = document.getElementById("login-view");
const appView = document.getElementById("app-view");
const loginMessage = document.getElementById("login-message");
const statusPill = document.getElementById("status-pill");
const ownerDetail = document.getElementById("owner-detail");
const petsGrid = document.getElementById("pets-grid");
const foodStoreTable = document.getElementById("food-store-table");
const medicineStoreTable = document.getElementById("medicine-store-table");
const plansTable = document.getElementById("plans-table");
const alertsBox = document.getElementById("alerts-box");
const planScope = document.getElementById("plan-scope");
let toastTimer = null;
let activeInfoChip = null;

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function formatOwnerId(ownerId) {
  return String(ownerId).padStart(5, "0");
}

function setStatus(message) {
  statusPill.textContent = message;
}

function normalizeApiMessage(message) {
  const text = String(message || "").trim();
  if (!text) return "请求失败";

  if (/owner_table_chk_3|check constraint/i.test(text)) {
    return "新密码格式不对，应至少 8 位并包含大小写和数字";
  }

  return text;
}

function showPopup(message) {
  let toast = document.getElementById("app-toast");
  if (!toast) {
    toast = document.createElement("div");
    toast.id = "app-toast";
    toast.className = "app-toast";
    document.body.appendChild(toast);
  }

  toast.textContent = message;
  toast.classList.add("show");

  if (toastTimer) {
    window.clearTimeout(toastTimer);
  }

  toastTimer = window.setTimeout(() => {
    toast.classList.remove("show");
  }, 2800);
}

function ensureFloatingTooltip() {
  let tooltip = document.getElementById("floating-tooltip");
  if (!tooltip) {
    tooltip = document.createElement("div");
    tooltip.id = "floating-tooltip";
    tooltip.className = "floating-tooltip";
    document.body.appendChild(tooltip);
  }
  return tooltip;
}

function positionFloatingTooltip(chip, tooltip) {
  const rect = chip.getBoundingClientRect();
  const tooltipRect = tooltip.getBoundingClientRect();
  const gap = 10;
  const minEdge = 12;

  let left = rect.left + rect.width / 2 - tooltipRect.width / 2;
  left = Math.max(minEdge, Math.min(left, window.innerWidth - tooltipRect.width - minEdge));

  let top = rect.top - tooltipRect.height - gap;
  if (top < minEdge) {
    top = rect.bottom + gap;
  }

  tooltip.style.left = `${left}px`;
  tooltip.style.top = `${top}px`;
}

function showInfoTooltip(chip) {
  const text = chip.dataset.tip;
  if (!text) return;
  const tooltip = ensureFloatingTooltip();
  tooltip.textContent = text;
  tooltip.classList.add("show");
  activeInfoChip = chip;
  positionFloatingTooltip(chip, tooltip);
}

function hideInfoTooltip() {
  const tooltip = document.getElementById("floating-tooltip");
  if (!tooltip) return;
  tooltip.classList.remove("show");
  activeInfoChip = null;
}

async function requestJson(url, options = {}) {
  const response = await fetch(url, {
    credentials: "same-origin",
    ...options,
  });
  const payload = await response.json();
  if (!response.ok) {
    throw new Error(normalizeApiMessage(payload.message));
  }
  return payload.data;
}

function showLogin(message = "尚未登录") {
  loginView.classList.remove("hidden");
  appView.classList.add("hidden");
  loginMessage.textContent = message;
}

function showApp() {
  loginView.classList.add("hidden");
  appView.classList.remove("hidden");
}

function parseDate(value) {
  if (!value) return null;
  return new Date(value);
}

function toDateInput(value) {
  const date = parseDate(value);
  if (!date) return "";
  const offset = date.getTimezoneOffset();
  const local = new Date(date.getTime() - offset * 60000);
  return local.toISOString().slice(0, 10);
}

function daysUntil(dateValue) {
  const target = parseDate(dateValue);
  if (!target) return null;
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const targetDay = new Date(target.getFullYear(), target.getMonth(), target.getDate());
  return Math.floor((targetDay - today) / (1000 * 60 * 60 * 24));
}

function expiryTag(dateValue) {
  const diff = daysUntil(dateValue);
  if (diff == null) return '<span class="tag">未知</span>';
  if (diff < 0) return '<span class="tag danger">已过期</span>';
  if (diff <= 15) return `<span class="tag warn">${diff} 天内到期</span>`;
  return '<span class="tag">正常</span>';
}

function expiryRowClass(dateValue) {
  const diff = daysUntil(dateValue);
  if (diff == null) return "";
  if (diff < 0) return "row-expired";
  if (diff <= 15) return "row-soon";
  return "";
}

function manufacturerInfoChip(phone, address) {
  if (!phone && !address) return "";
  const tip = `厂商电话：${phone || "未填"}\n厂商地址：${address || "未填"}`;
  return `<span class="info-chip" data-tip="${escapeHtml(tip)}">i</span>`;
}

function formatPetLabel(pet) {
  return `${pet.pet_name}（${pet.pet_category}）`;
}

function getCurrentPet() {
  return state.pets.find((pet) => pet.pet_id === state.selectedPetId) || null;
}

function uniqueFoodInventoryOptions() {
  const seen = new Set();
  return state.foodStore.filter((item) => {
    const key = String(item.food_id);
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

function renderProfile() {
  if (!state.me) {
    ownerDetail.className = "plain-panel empty-panel";
    ownerDetail.textContent = "请先登录";
    return;
  }

  document.getElementById("sidebar-owner-name").textContent = state.me.owner_nickname;
  document.getElementById("sidebar-owner-code").textContent = state.me.owner_code || formatOwnerId(state.me.owner_id);

  ownerDetail.className = "plain-panel";
  ownerDetail.innerHTML = `
    <div class="profile-header">
      <div>
        <h4>${escapeHtml(state.me.owner_nickname)}</h4>
        <div class="muted">账号 ${escapeHtml(state.me.owner_code || formatOwnerId(state.me.owner_id))}</div>
      </div>
      <span class="tag">${escapeHtml(state.me.owner_sex || "未填性别")}</span>
    </div>
    <dl class="detail-grid">
      <div><dt>手机号</dt><dd>${escapeHtml(state.me.owner_phone || "未填")}</dd></div>
      <div><dt>生日</dt><dd>${escapeHtml(state.me.owner_birthday || "未填")}</dd></div>
      <div><dt>地址</dt><dd>${escapeHtml(state.me.owner_address || "未填")}</dd></div>
      <div><dt>主人编号</dt><dd>${escapeHtml(state.me.owner_id)}</dd></div>
    </dl>
  `;
}

function fillOwnerForm() {
  if (!state.me) return;
  document.getElementById("owner-edit-nickname").value = state.me.owner_nickname || "";
  document.getElementById("owner-edit-phone").value = state.me.owner_phone || "";
  document.getElementById("owner-edit-birthday").value = toDateInput(state.me.owner_birthday);
  document.getElementById("owner-edit-address").value = state.me.owner_address || "";
  document.getElementById("owner-edit-sex").value = state.me.owner_sex || "";
}

function renderPets() {
  document.querySelector("#section-pets h3").textContent = `我的宠物（${state.pets.length}）`;

  if (!state.pets.length) {
    petsGrid.className = "list-panel empty-panel";
    petsGrid.textContent = "当前账号下没有宠物";
    return;
  }

  petsGrid.className = "list-panel";
  petsGrid.innerHTML = state.pets.map((pet) => {
    const extra = pet.pet_category === "猫"
      ? `剪爪周期：${pet.cat_claw_cycle ?? "未填"} 天 · 猫砂：${pet.cat_litter ?? "未填"}`
      : `遛狗等级：${pet.dog_walk_level ?? "未填"} · 犬证号：${pet.dog_license_no ?? "未填"}`;
    const isActive = state.selectedPetId === Number(pet.pet_id);

    return `
      <article class="pet-item ${isActive ? "is-active" : ""}">
        <div class="pet-meta">
          <strong>${escapeHtml(pet.pet_name)}</strong>
          <div class="muted">${escapeHtml(pet.pet_category)} · ${escapeHtml(pet.pet_sex || "未填性别")}</div>
          <div class="muted">生日：${escapeHtml(pet.pet_birthday || "未填")}</div>
          <div class="muted">${escapeHtml(extra)}</div>
        </div>
        <button class="btn btn-secondary load-pet-plans" data-pet-id="${pet.pet_id}">
          ${isActive ? "当前已筛选" : "查看计划"}
        </button>
      </article>
    `;
  }).join("");

  petsGrid.querySelectorAll(".load-pet-plans").forEach((button) => {
    button.addEventListener("click", async () => {
      state.selectedPetId = Number(button.dataset.petId);
      await loadPlans();
    });
  });

}

function renderTable(container, columns, rows, emptyText, rowClassGetter = null) {
  if (!rows.length) {
    container.className = "table-panel empty-panel";
    container.textContent = emptyText;
    return;
  }

  container.className = "table-panel";
  const head = columns.map((column) => `<th>${column.label}</th>`).join("");
  const body = rows.map((row) => `
    <tr class="${rowClassGetter ? rowClassGetter(row) : ""}">
      ${columns.map((column) => `<td>${column.render ? column.render(row[column.key], row) : escapeHtml(row[column.key] ?? "")}</td>`).join("")}
    </tr>
  `).join("");
  container.innerHTML = `<table><thead><tr>${head}</tr></thead><tbody>${body}</tbody></table>`;
}

function renderFoodStore() {
  renderTable(
    foodStoreTable,
    [
      {
        key: "food_name",
        label: "食品",
        render: (value, row) => `
          <div class="inventory-main">
            <strong>${escapeHtml(value)}${manufacturerInfoChip(row.food_manu_phone, row.food_manu_addr)}</strong>
            <span class="inventory-sub">${escapeHtml(row.food_category)} · 批次 ${escapeHtml(row.food_store_batch_no)}</span>
          </div>
        `,
      },
      { key: "food_store_expire_time", label: "过期日期" },
      { key: "food_store_remaining_amount", label: "剩余量" },
      { key: "food_store_expire_time", label: "状态", render: (value) => expiryTag(value) },
    ],
    state.foodStore,
    "当前账号下没有食品库存",
    (row) => expiryRowClass(row.food_store_expire_time)
  );
}

function renderMedicineStore() {
  renderTable(
    medicineStoreTable,
    [
      {
        key: "medicine_name",
        label: "药物",
        render: (value, row) => `
          <div class="inventory-main">
            <strong>${escapeHtml(value)}${manufacturerInfoChip(row.medicine_manu_phone, row.medicine_manu_addr)}</strong>
            <span class="inventory-sub">${escapeHtml(row.medicine_category)} · 批次 ${escapeHtml(row.medicine_batch_no)}</span>
          </div>
        `,
      },
      { key: "medicine_instruction", label: "说明" },
      { key: "medicine_store_expire_time", label: "过期日期" },
      { key: "medicine_store_remaining_amount", label: "剩余量" },
      { key: "medicine_store_expire_time", label: "状态", render: (value) => expiryTag(value) },
    ],
    state.medicineStore,
    "当前账号下没有药物库存",
    (row) => expiryRowClass(row.medicine_store_expire_time)
  );
}

function renderPlans() {
  const currentPet = getCurrentPet();
  const scopeText = currentPet ? `当前显示：${currentPet.pet_name} 的计划` : "当前显示：全部宠物";
  document.querySelector("#section-plans h3").textContent = `喂药计划（${state.plans.length}）`;
  planScope.textContent = scopeText;

  renderTable(
    plansTable,
    [
      {
        key: "pet_name",
        label: "宠物 / 计划",
        render: (value, row) => `
          <div class="plan-title">
            <strong>${escapeHtml(value)}</strong>
            <span class="muted">${escapeHtml(row.medicine_name)} · ${escapeHtml(row.medicine_feed_amount)} 片 / 次</span>
          </div>
        `,
      },
      { key: "medicine_feed_time", label: "喂药时间" },
      {
        key: "total_remaining_amount",
        label: "库存情况",
        render: (value, row) => {
          const remaining = value == null ? null : Number(value);
          if (remaining == null || Number.isNaN(remaining)) return '<span class="tag danger">无库存</span>';
          if (remaining < Number(row.medicine_feed_amount)) return `<span class="tag warn">库存不足（剩余 ${remaining}）</span>`;
          return `<span class="tag">可执行（剩余 ${remaining}）</span>`;
        }
      },
      {
        key: "plan_id",
        label: "执行",
        render: (value, row) => {
          const remaining = row.total_remaining_amount == null ? null : Number(row.total_remaining_amount);
          const disabled = remaining == null || remaining < Number(row.medicine_feed_amount);
          return `
            <div class="action-cell">
              <button class="btn btn-primary execute-plan-btn" data-plan-id="${value}" ${disabled ? "disabled" : ""}>执行</button>
              <span class="action-hint">${disabled ? "系统找不到足够库存的可用批次" : "系统会自动选择最早到期且库存足够的批次"}</span>
            </div>
          `;
        }
      }
    ],
    state.plans,
    "当前没有喂药计划"
  );

  plansTable.querySelectorAll(".execute-plan-btn").forEach((button) => {
    button.addEventListener("click", async () => {
      const planId = Number(button.dataset.planId);
      await executePlan(planId);
    });
  });
}

function renderAlerts() {
  const alerts = [];

  state.foodStore.forEach((item) => {
    const diff = daysUntil(item.food_store_expire_time);
    if (diff != null && diff <= 15) {
      alerts.push({
        type: diff < 0 ? "danger" : "warn",
        title: `${item.food_name}（食品）`,
        text: diff < 0 ? `已过期 ${Math.abs(diff)} 天` : `${diff} 天内到期`,
      });
    }
  });

  state.medicineStore.forEach((item) => {
    const diff = daysUntil(item.medicine_store_expire_time);
    if (diff != null && diff <= 15) {
      alerts.push({
        type: diff < 0 ? "danger" : "warn",
        title: `${item.medicine_name}（药物）`,
        text: diff < 0 ? `已过期 ${Math.abs(diff)} 天` : `${diff} 天内到期`,
      });
    }
  });

  alerts.sort((left, right) => {
    const leftScore = left.type === "danger" ? 0 : 1;
    const rightScore = right.type === "danger" ? 0 : 1;
    return leftScore - rightScore;
  });

  if (!alerts.length) {
    alertsBox.className = "alerts-box empty-panel";
    alertsBox.textContent = "当前没有过期或临近到期提醒";
    return;
  }

  alertsBox.className = "alerts-box alert-list";
  alertsBox.innerHTML = alerts.map((alert) => `
    <article class="alert-item">
      <strong>${escapeHtml(alert.title)}</strong>
      <span class="tag ${alert.type === "danger" ? "danger" : "warn"}">${alert.text}</span>
    </article>
  `).join("");
}

function renderPetExtraFields(category, pet = null) {
  const container = document.getElementById("pet-extra-fields");
  if (category === "狗") {
    container.innerHTML = `
      <label>
        <span>遛狗等级</span>
        <input id="pet-edit-dog-walk-level" type="text" value="${escapeHtml(pet?.dog_walk_level || "")}">
      </label>
      <label>
        <span>犬证号</span>
        <input id="pet-edit-dog-license-no" type="text" value="${escapeHtml(pet?.dog_license_no || "")}">
      </label>
    `;
    return;
  }

  container.innerHTML = `
    <label>
      <span>剪爪周期</span>
      <input id="pet-edit-cat-claw-cycle" type="number" min="1" value="${escapeHtml(pet?.cat_claw_cycle || "")}">
    </label>
    <label>
      <span>常用猫砂</span>
      <input id="pet-edit-cat-litter" type="text" value="${escapeHtml(pet?.cat_litter || "")}">
    </label>
  `;
}

function syncPetEditor() {
  const select = document.getElementById("pet-edit-id");
  const petId = Number(select.value);
  const pet = state.pets.find((item) => item.pet_id === petId);
  if (!pet) return;

  document.getElementById("pet-edit-name").value = pet.pet_name || "";
  document.getElementById("pet-edit-sex").value = pet.pet_sex || "";
  document.getElementById("pet-edit-birthday").value = toDateInput(pet.pet_birthday);
  document.getElementById("pet-edit-category").value = pet.pet_category;
  renderPetExtraFields(pet.pet_category, pet);
}

function renderOwnerAndPetEditors() {
  fillOwnerForm();

  const petSelect = document.getElementById("pet-edit-id");
  const petOptions = state.pets.map((pet) => `<option value="${pet.pet_id}">${escapeHtml(formatPetLabel(pet))}</option>`).join("");
  petSelect.innerHTML = petOptions || '<option value="">暂无宠物</option>';
  if (state.pets.length) {
    petSelect.value = String(state.pets[0].pet_id);
    syncPetEditor();
  } else {
    renderPetExtraFields("猫");
  }
}

function renderFeedEditor() {
  const petSelect = document.getElementById("feed-pet-id");
  petSelect.innerHTML = state.pets.map((pet) => `<option value="${pet.pet_id}">${escapeHtml(formatPetLabel(pet))}</option>`).join("");
  syncFeedFoodOptions();
}

function syncFeedFoodOptions() {
  const petId = Number(document.getElementById("feed-pet-id").value);
  const pet = state.pets.find((item) => item.pet_id === petId);
  const foodSelect = document.getElementById("feed-food-id");
  const options = uniqueFoodInventoryOptions().filter((item) => !pet || item.food_category === pet.pet_category);
  foodSelect.innerHTML = options.map((item) => `<option value="${item.food_id}">${escapeHtml(item.food_name)}（剩余 ${escapeHtml(item.food_store_remaining_amount)}）</option>`).join("");
}

function renderDictionaryEditors() {
  document.getElementById("food-create-id").innerHTML = state.foods.map((food) => `
    <option value="${food.food_id}">${escapeHtml(food.food_name)}（${escapeHtml(food.food_category)}）</option>
  `).join("");

  document.getElementById("medicine-create-id").innerHTML = state.medicines.map((medicine) => `
    <option value="${medicine.medicine_id}">${escapeHtml(medicine.medicine_name)}（${escapeHtml(medicine.medicine_category)}）</option>
  `).join("");

  document.getElementById("food-update-key").innerHTML = state.foodStore.map((item) => `
    <option value="${item.food_id}|${item.food_store_batch_no}">
      ${escapeHtml(item.food_name)} · 批次 ${escapeHtml(item.food_store_batch_no)}
    </option>
  `).join("");

  document.getElementById("medicine-update-key").innerHTML = state.medicineStore.map((item) => `
    <option value="${item.medicine_id}|${item.medicine_batch_no}">
      ${escapeHtml(item.medicine_name)} · 批次 ${escapeHtml(item.medicine_batch_no)}
    </option>
  `).join("");

  syncFoodUpdateForm();
  syncMedicineUpdateForm();
}

function syncFoodUpdateForm() {
  const value = document.getElementById("food-update-key").value;
  if (!value) return;
  const [foodId, batchNo] = value.split("|").map(Number);
  const item = state.foodStore.find((row) => row.food_id === foodId && row.food_store_batch_no === batchNo);
  if (!item) return;
  document.getElementById("food-update-expire").value = toDateInput(item.food_store_expire_time);
  document.getElementById("food-update-amount").value = item.food_store_remaining_amount;
}

function syncMedicineUpdateForm() {
  const value = document.getElementById("medicine-update-key").value;
  if (!value) return;
  const [medicineId, batchNo] = value.split("|").map(Number);
  const item = state.medicineStore.find((row) => row.medicine_id === medicineId && row.medicine_batch_no === batchNo);
  if (!item) return;
  document.getElementById("medicine-update-expire").value = toDateInput(item.medicine_store_expire_time);
  document.getElementById("medicine-update-amount").value = item.medicine_store_remaining_amount;
}

async function login(event) {
  event.preventDefault();
  const payload = {
    owner_id: document.getElementById("login-owner-id").value.trim(),
    password: document.getElementById("login-password").value,
  };

  loginMessage.textContent = "登录中...";
  try {
    state.me = await requestJson("/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    showApp();
    setStatus("登录成功");
    await loadAll();
  } catch (error) {
    loginMessage.textContent = error.message;
    showLogin(error.message);
  }
}

async function logout() {
  await requestJson("/auth/logout", { method: "POST" });
  state.me = null;
  state.pets = [];
  state.foodStore = [];
  state.medicineStore = [];
  state.plans = [];
  state.foods = [];
  state.medicines = [];
  state.selectedPetId = null;
  renderProfile();
  showLogin("已退出登录");
}

async function loadMe() {
  state.me = await requestJson("/me");
  renderProfile();
  fillOwnerForm();
}

async function loadPets() {
  setStatus("加载宠物中...");
  state.pets = await requestJson("/me/pets");
  renderPets();
  renderOwnerAndPetEditors();
  renderFeedEditor();
  setStatus("宠物已更新");
}

async function loadFoodStore() {
  const expireBefore = document.getElementById("food-expire-before").value;
  setStatus("加载食品库存中...");
  state.foodStore = await requestJson(`/me/food-store?expire_before=${encodeURIComponent(expireBefore)}`);
  renderFoodStore();
  renderAlerts();
  renderFeedEditor();
  renderDictionaryEditors();
  setStatus("食品库存已更新");
}

async function loadMedicineStore() {
  const expireBefore = document.getElementById("medicine-expire-before").value;
  setStatus("加载药物库存中...");
  state.medicineStore = await requestJson(`/me/medicine-store?expire_before=${encodeURIComponent(expireBefore)}`);
  renderMedicineStore();
  renderAlerts();
  renderDictionaryEditors();
  setStatus("药物库存已更新");
}

async function loadDictionaries() {
  const [foods, medicines] = await Promise.all([
    requestJson("/foods"),
    requestJson("/medicines"),
  ]);
  state.foods = foods;
  state.medicines = medicines;
  renderDictionaryEditors();
}

async function loadPlans() {
  const beforeTime = document.getElementById("plans-before-time").value;
  const qs = new URLSearchParams();
  if (state.selectedPetId) {
    qs.set("pet_id", String(state.selectedPetId));
  }
  if (beforeTime) {
    qs.set("before_time", `${beforeTime}:00`);
  }

  setStatus("加载喂药计划中...");
  state.plans = await requestJson(`/me/plans?${qs.toString()}`);
  renderPets();
  renderPlans();
  setStatus("喂药计划已更新");
}

async function loadAll() {
  await loadMe();
  await Promise.all([loadPets(), loadFoodStore(), loadMedicineStore(), loadDictionaries()]);
  state.selectedPetId = null;
  await loadPlans();
}

async function executePlan(planId) {
  setStatus("执行喂药中...");
  try {
    const result = await requestJson(`/plans/${planId}/execute`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    });
    showPopup("喂药计划执行成功");
    setStatus("执行成功");
    await Promise.all([loadMedicineStore(), loadPlans()]);
  } catch (error) {
    showPopup(error.message || "执行失败");
    setStatus("执行失败");
  }
}

async function submitOwnerEdit(event) {
  event.preventDefault();
  const payload = {
    owner_nickname: document.getElementById("owner-edit-nickname").value.trim(),
    owner_phone: document.getElementById("owner-edit-phone").value.trim(),
    owner_birthday: document.getElementById("owner-edit-birthday").value || null,
    owner_address: document.getElementById("owner-edit-address").value.trim(),
    owner_sex: document.getElementById("owner-edit-sex").value || null,
  };

  const result = await requestJson("/me", {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  state.me = result;
  renderProfile();
  fillOwnerForm();
  showPopup("主人信息已更新");
}

async function submitPasswordEdit(event) {
  event.preventDefault();
  const oldPassword = document.getElementById("old-password").value;
  const newPassword = document.getElementById("new-password").value;
  if (!oldPassword) {
    throw new Error("请输入旧密码");
  }
  if (!newPassword) {
    throw new Error("请输入新密码");
  }
  const payload = {
    old_password: oldPassword,
    new_password: newPassword,
  };
  await requestJson("/me/password", {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  document.getElementById("password-form").reset();
  showPopup("密码修改成功");
}

async function submitPetEdit(event) {
  event.preventDefault();
  const petId = Number(document.getElementById("pet-edit-id").value);
  const category = document.getElementById("pet-edit-category").value;
  const payload = {
    pet_name: document.getElementById("pet-edit-name").value.trim(),
    pet_sex: document.getElementById("pet-edit-sex").value || null,
    pet_birthday: document.getElementById("pet-edit-birthday").value || null,
    pet_category: category,
  };
  if (category === "猫") {
    payload.cat_claw_cycle = document.getElementById("pet-edit-cat-claw-cycle").value || null;
    payload.cat_litter = document.getElementById("pet-edit-cat-litter").value.trim();
  } else {
    payload.dog_walk_level = document.getElementById("pet-edit-dog-walk-level").value.trim();
    payload.dog_license_no = document.getElementById("pet-edit-dog-license-no").value.trim();
  }
  const result = await requestJson(`/pets/${petId}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  await loadPets();
  if (state.selectedPetId === petId) {
    await loadPlans();
  }
}

async function submitFoodFeed(event) {
  event.preventDefault();
  const payload = {
    pet_id: Number(document.getElementById("feed-pet-id").value),
    food_id: Number(document.getElementById("feed-food-id").value),
    amount: Number(document.getElementById("feed-amount").value),
  };
  await requestJson("/me/food-feed", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  showPopup("食品喂食成功");
  await loadFoodStore();
}

async function submitFoodCreate(event) {
  event.preventDefault();
  const payload = {
    food_id: Number(document.getElementById("food-create-id").value),
    food_store_batch_no: Number(document.getElementById("food-create-batch").value),
    food_store_expire_time: document.getElementById("food-create-expire").value,
    food_store_remaining_amount: Number(document.getElementById("food-create-amount").value),
  };
  await requestJson("/me/food-store", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  showPopup("食品库存已新增");
  event.target.reset();
  await loadFoodStore();
}

async function submitFoodUpdate(event) {
  event.preventDefault();
  const [foodId, batchNo] = document.getElementById("food-update-key").value.split("|").map(Number);
  const payload = {
    food_store_expire_time: document.getElementById("food-update-expire").value,
    food_store_remaining_amount: Number(document.getElementById("food-update-amount").value),
  };
  await requestJson(`/me/food-store/${foodId}/${batchNo}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  showPopup("食品库存已更新");
  await loadFoodStore();
}

async function submitMedicineCreate(event) {
  event.preventDefault();
  const payload = {
    medicine_id: Number(document.getElementById("medicine-create-id").value),
    medicine_batch_no: Number(document.getElementById("medicine-create-batch").value),
    medicine_store_expire_time: document.getElementById("medicine-create-expire").value,
    medicine_store_remaining_amount: Number(document.getElementById("medicine-create-amount").value),
  };
  await requestJson("/me/medicine-store", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  event.target.reset();
  await loadMedicineStore();
}

async function submitMedicineUpdate(event) {
  event.preventDefault();
  const [medicineId, batchNo] = document.getElementById("medicine-update-key").value.split("|").map(Number);
  const payload = {
    medicine_store_expire_time: document.getElementById("medicine-update-expire").value,
    medicine_store_remaining_amount: Number(document.getElementById("medicine-update-amount").value),
  };
  await requestJson(`/me/medicine-store/${medicineId}/${batchNo}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  await loadMedicineStore();
}

async function withFormAction(action, options = {}) {
  const { popupOnError = false } = options;
  try {
    setStatus("处理中...");
    await action();
    setStatus("操作成功");
  } catch (error) {
    setStatus("操作失败");
    if (popupOnError) {
      showPopup(error.message || "操作失败");
    }
  }
}

async function boot() {
  try {
    state.me = await requestJson("/me");
    showApp();
    await loadAll();
  } catch {
    showLogin("请先登录");
  }
}

document.getElementById("login-form").addEventListener("submit", login);
document.getElementById("logout-btn").addEventListener("click", () => withFormAction(logout));
document.getElementById("refresh-all").addEventListener("click", () => withFormAction(loadAll));
document.getElementById("load-pets").addEventListener("click", () => withFormAction(loadPets));
document.getElementById("load-food-store").addEventListener("click", () => withFormAction(loadFoodStore));
document.getElementById("load-medicine-store").addEventListener("click", () => withFormAction(loadMedicineStore));
document.getElementById("load-plans").addEventListener("click", () => withFormAction(loadPlans));
document.getElementById("clear-plan-filter").addEventListener("click", () => withFormAction(async () => {
  state.selectedPetId = null;
  await loadPlans();
}));

document.getElementById("owner-edit-form").addEventListener("submit", (event) => withFormAction(() => submitOwnerEdit(event), {
  popupOnError: true,
}));
document.getElementById("password-form").addEventListener("submit", (event) => withFormAction(() => submitPasswordEdit(event), {
  popupOnError: true,
}));
document.getElementById("pet-edit-form").addEventListener("submit", (event) => withFormAction(() => submitPetEdit(event)));
document.getElementById("food-feed-form").addEventListener("submit", (event) => withFormAction(() => submitFoodFeed(event), {
  popupOnError: true,
}));
document.getElementById("food-create-form").addEventListener("submit", (event) => withFormAction(() => submitFoodCreate(event), {
  popupOnError: true,
}));
document.getElementById("food-update-form").addEventListener("submit", (event) => withFormAction(() => submitFoodUpdate(event), {
  popupOnError: true,
}));
document.getElementById("medicine-create-form").addEventListener("submit", (event) => withFormAction(() => submitMedicineCreate(event)));
document.getElementById("medicine-update-form").addEventListener("submit", (event) => withFormAction(() => submitMedicineUpdate(event)));

document.getElementById("pet-edit-id").addEventListener("change", syncPetEditor);
document.getElementById("pet-edit-category").addEventListener("change", (event) => renderPetExtraFields(event.target.value));
document.getElementById("feed-pet-id").addEventListener("change", syncFeedFoodOptions);
document.getElementById("food-update-key").addEventListener("change", syncFoodUpdateForm);
document.getElementById("medicine-update-key").addEventListener("change", syncMedicineUpdateForm);

document.querySelectorAll(".nav-link").forEach((button) => {
  button.addEventListener("click", () => {
    const target = document.getElementById(button.dataset.target);
    if (target) {
      target.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  });
});

document.addEventListener("mouseover", (event) => {
  const chip = event.target.closest(".info-chip");
  if (!chip) return;
  showInfoTooltip(chip);
});

document.addEventListener("mouseout", (event) => {
  const chip = event.target.closest(".info-chip");
  if (!chip) return;
  const related = event.relatedTarget;
  if (related && chip.contains(related)) return;
  hideInfoTooltip();
});

window.addEventListener("scroll", () => {
  if (!activeInfoChip) return;
  const tooltip = document.getElementById("floating-tooltip");
  if (!tooltip || !tooltip.classList.contains("show")) return;
  positionFloatingTooltip(activeInfoChip, tooltip);
}, true);

window.addEventListener("resize", () => {
  if (!activeInfoChip) return;
  const tooltip = document.getElementById("floating-tooltip");
  if (!tooltip || !tooltip.classList.contains("show")) return;
  positionFloatingTooltip(activeInfoChip, tooltip);
});

boot();
