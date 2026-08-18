(function () {
  "use strict";

  var buttons = Array.prototype.slice.call(document.querySelectorAll("[data-view-button]"));
  var views = Array.prototype.slice.call(document.querySelectorAll("[data-view]"));
  var search = document.getElementById("global-search");
  var status = document.getElementById("search-status");
  var statusTimer;

  function currentView() {
    var active = document.querySelector("[data-view].active");
    return active ? active.getAttribute("data-view") : "overview";
  }

  function activateView(name, updateHash) {
    var exists = views.some(function (view) {
      return view.getAttribute("data-view") === name;
    });
    if (!exists) name = "overview";

    views.forEach(function (view) {
      view.classList.toggle("active", view.getAttribute("data-view") === name);
    });
    buttons.forEach(function (button) {
      var active = button.getAttribute("data-view-button") === name;
      button.classList.toggle("active", active);
      button.setAttribute("aria-current", active ? "page" : "false");
    });
    if (updateHash && window.history && window.history.replaceState) {
      window.history.replaceState(null, "", "#" + name);
    }
    if (name !== "gifts") closeGift();
    applySearch(false);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  function showStatus(message) {
    window.clearTimeout(statusTimer);
    status.textContent = message;
    status.classList.add("visible");
    statusTimer = window.setTimeout(function () {
      status.classList.remove("visible");
    }, 1500);
  }

  function setEmptyState(view, visible) {
    var empty = view.querySelector("[data-no-results]");
    if (empty) empty.classList.toggle("visible", visible);
  }

  var modal = document.querySelector("[data-gift-modal]");
  var modalWindow = modal.querySelector(".gift-modal-window");
  var modalTitle = modal.querySelector("[data-gift-modal-title]");
  var modalPosition = modal.querySelector("[data-gift-modal-position]");
  var modalBody = modal.querySelector(".gift-modal-body");
  var lastFocused = null;

  function giftRows() {
    return Array.prototype.slice.call(
      document.querySelectorAll('[data-view="gifts"] [data-gift-row]')
    );
  }

  // Navigation steps through what the reader can currently see, so a search
  // narrows the sequence the arrows walk.
  function visibleGiftRows() {
    return giftRows().filter(function (row) { return !row.hidden; });
  }

  function openGift(giftId) {
    var detail = modalBody.querySelector('[data-gift-detail][data-gift-id="' + giftId + '"]');
    if (!detail) return;

    giftRows().forEach(function (row) {
      var selected = row.getAttribute("data-gift-id") === giftId;
      row.classList.toggle("selected", selected);
      row.setAttribute("aria-selected", selected ? "true" : "false");
    });
    Array.prototype.slice.call(modalBody.querySelectorAll("[data-gift-detail]")).forEach(function (other) {
      other.hidden = other !== detail;
    });

    modalTitle.textContent = detail.getAttribute("data-gift-name") || "GIFT detail";
    var visible = visibleGiftRows();
    var position = -1;
    visible.forEach(function (row, index) {
      if (row.getAttribute("data-gift-id") === giftId) position = index;
    });
    modalPosition.textContent = position === -1 ? "" : (position + 1) + " / " + visible.length;

    if (modal.hidden) {
      lastFocused = document.activeElement;
      modal.hidden = false;
      document.body.classList.add("modal-open");
    }
    modalBody.scrollTop = 0;
    modalWindow.focus();
  }

  function closeGift() {
    if (modal.hidden) return;
    modal.hidden = true;
    document.body.classList.remove("modal-open");
    if (lastFocused && document.contains(lastFocused)) lastFocused.focus();
    lastFocused = null;
  }

  function stepGift(offset) {
    var open = modalBody.querySelector("[data-gift-detail]:not([hidden])");
    if (!open) return;
    var visible = visibleGiftRows();
    var current = -1;
    visible.forEach(function (row, index) {
      if (row.getAttribute("data-gift-id") === open.getAttribute("data-gift-id")) current = index;
    });
    if (current === -1 || !visible.length) return;
    var next = (current + offset + visible.length) % visible.length;
    openGift(visible[next].getAttribute("data-gift-id"));
  }

  var giftBody = document.querySelector(".gift-summary-table tbody");
  var giftTable = document.querySelector(".gift-summary-table");
  var giftOrder = giftRows();
  var groupSelects = [
    document.querySelector("[data-gift-group-select]"),
    document.querySelector("[data-gift-group-select-2]")
  ].filter(Boolean);
  var resetAnchors = document.querySelector("[data-gift-reset]");
  var collapsedGroups = {};

  // A select's value is the row's data-attribute suffix, so a new grouping axis
  // needs an option and an attribute on the row, not a change here. Selecting
  // two axes groups by their combination; picking the same axis twice is
  // deduplicated so a group cannot be labelled "anabolic . anabolic".
  function groupAxes() {
    var axes = [];
    groupSelects.forEach(function (select) {
      var value = select.value;
      if (value !== "none" && axes.indexOf(value) === -1) axes.push(value);
    });
    return axes;
  }

  function isGrouped() {
    return groupAxes().length > 0;
  }

  // A row's group path, one key per selected axis. Each key carries its
  // ancestors, so the "catabolic" subgroup under "monosaccharide" is a
  // different key from the one under "uronate" and the two never merge.
  var SEPARATOR = "\u0000";

  function giftGroupKeys(row) {
    var path = "";
    return groupAxes().map(function (axis) {
      var value = row.getAttribute("data-" + axis) || "unclassified";
      path = path ? path + SEPARATOR + value : value;
      return path;
    });
  }

  function groupLabel(key) {
    var parts = key.split(SEPARATOR);
    return parts[parts.length - 1];
  }

  // A subgroup is hidden when any ancestor is collapsed, not only its parent,
  // so collapsing the top level folds the whole branch away.
  function ancestorCollapsed(key) {
    var parts = key.split(SEPARATOR);
    for (var i = 1; i < parts.length; i += 1) {
      if (collapsedGroups[parts.slice(0, i).join(SEPARATOR)]) return true;
    }
    return false;
  }

  function anchorFilter(role) {
    var select = document.querySelector('[data-gift-anchor-filter="' + role + '"]');
    return select ? select.value : "";
  }

  // Anchor lists are stored space-delimited and space-padded, so a padded
  // needle matches whole ids only.
  function hasAnchor(row, attribute, anchorId) {
    if (!anchorId) return true;
    return (row.getAttribute(attribute) || "").indexOf(" " + anchorId + " ") !== -1;
  }

  function groupRows() {
    return Array.prototype.slice.call(giftBody.querySelectorAll("[data-gift-group]"));
  }

  function buildGroupRow(key, level) {
    var row = document.createElement("tr");
    row.className = "gift-group-row";
    row.setAttribute("data-gift-group", key);
    row.setAttribute("data-gift-group-level", String(level));
    var cell = document.createElement("td");
    cell.colSpan = giftTable.tHead.rows[0].cells.length;
    var toggle = document.createElement("button");
    toggle.type = "button";
    toggle.setAttribute("data-gift-group-toggle", key);
    toggle.setAttribute("aria-expanded", collapsedGroups[key] ? "false" : "true");
    toggle.innerHTML =
      '<span class="gift-group-caret" aria-hidden="true"></span><strong></strong><small></small>';
    toggle.querySelector("strong").textContent = groupLabel(key);
    toggle.addEventListener("click", function () {
      collapsedGroups[key] = !collapsedGroups[key];
      applySearch(false);
    });
    cell.appendChild(toggle);
    row.appendChild(cell);
    return row;
  }

  // Rows are laid out in document order, so grouping rewrites the body rather
  // than duplicating it: one node per GIFT keeps selection and the modal in sync.
  // Each selected axis adds a nesting level: the second axis renders as
  // subgroup headers inside the first rather than as a combined label.
  function layoutGifts() {
    var axes = groupAxes();
    groupRows().forEach(function (row) { row.remove(); });
    giftTable.classList.toggle("grouped", axes.length > 0);
    if (!axes.length) {
      giftOrder.forEach(function (row) { giftBody.appendChild(row); });
      return;
    }

    function emit(rows, depth) {
      var keys = [];
      rows.forEach(function (row) {
        var key = giftGroupKeys(row)[depth];
        if (keys.indexOf(key) === -1) keys.push(key);
      });
      keys.sort();
      keys.forEach(function (key) {
        var members = rows.filter(function (row) {
          return giftGroupKeys(row)[depth] === key;
        });
        giftBody.appendChild(buildGroupRow(key, depth + 1));
        if (depth + 1 < axes.length) {
          emit(members, depth + 1);
        } else {
          members.forEach(function (row) { giftBody.appendChild(row); });
        }
      });
    }

    emit(giftOrder, 0);
  }

  function filterGifts(query) {
    var view = document.querySelector('[data-view="gifts"]');
    var grouped = isGrouped();
    var input = anchorFilter("input");
    var output = anchorFilter("output");
    var matched = {};
    var count = 0;

    giftRows().forEach(function (row) {
      var matches =
        (!query || row.getAttribute("data-search").indexOf(query) !== -1) &&
        hasAnchor(row, "data-inputs", input) &&
        hasAnchor(row, "data-outputs", output);
      // A row counts towards every level it sits in, so a parent header reports
      // the total across its subgroups.
      var keys = grouped ? giftGroupKeys(row) : [];
      if (matches) {
        count += 1;
        keys.forEach(function (key) { matched[key] = (matched[key] || 0) + 1; });
      }
      // A collapsed group hides matching rows without dropping them from the
      // result count its header reports.
      var withinCollapsed = keys.some(function (key) {
        return Boolean(collapsedGroups[key]);
      });
      row.hidden = !matches || (grouped && withinCollapsed);
    });

    groupRows().forEach(function (row) {
      var key = row.getAttribute("data-gift-group");
      var total = matched[key] || 0;
      // An empty group disappears, and a subgroup also disappears while an
      // ancestor is collapsed.
      row.hidden = total === 0 || ancestorCollapsed(key);
      var toggle = row.querySelector("[data-gift-group-toggle]");
      toggle.setAttribute("aria-expanded", collapsedGroups[key] ? "false" : "true");
      toggle.querySelector("small").textContent = total + (total === 1 ? " GIFT" : " GIFTs");
    });

    if (resetAnchors) resetAnchors.hidden = !input && !output;
    setEmptyState(view, count === 0);
    return count;
  }

  function filterChangelog(query) {
    var view = document.querySelector('[data-view="changelog"]');
    var rows = Array.prototype.slice.call(view.querySelectorAll(".changelog-row"));
    var count = 0;
    rows.forEach(function (row) {
      var matches = !query || row.getAttribute("data-search").indexOf(query) !== -1;
      row.hidden = !matches;
      if (matches) count += 1;
    });
    setEmptyState(view, count === 0);
    return count;
  }

  function filterSchema(query) {
    var view = document.querySelector('[data-view="schema"]');
    var cards = Array.prototype.slice.call(view.querySelectorAll(".schema-card"));
    var count = 0;
    cards.forEach(function (card) {
      var matches = !query || card.getAttribute("data-search").indexOf(query) !== -1;
      card.hidden = !matches;
      if (matches) count += 1;
    });
    setEmptyState(view, count === 0);
    return count;
  }

  function filterTables(query) {
    var view = document.querySelector('[data-view="tables"]');
    var panels = Array.prototype.slice.call(view.querySelectorAll("[data-table-panel]"));
    var visiblePanels = 0;
    var visibleRows = 0;
    panels.forEach(function (panel) {
      var tableMatches = !query || panel.getAttribute("data-table-name").indexOf(query) !== -1;
      var rows = Array.prototype.slice.call(panel.querySelectorAll("[data-table-row]"));
      var matchingRows = 0;
      rows.forEach(function (row) {
        var matches = tableMatches || row.getAttribute("data-search").indexOf(query) !== -1;
        row.hidden = !matches;
        if (matches) matchingRows += 1;
      });
      var matchesPanel = tableMatches || matchingRows > 0;
      panel.hidden = !matchesPanel;
      if (matchesPanel) {
        visiblePanels += 1;
        visibleRows += matchingRows;
      }
    });
    setEmptyState(view, visiblePanels === 0);
    return { panels: visiblePanels, rows: visibleRows };
  }

  function applySearch(announce) {
    var query = search.value.trim().toLowerCase();
    var section = currentView();
    var message = "";

    if (section === "gifts") {
      var giftCount = filterGifts(query);
      message = giftCount + (giftCount === 1 ? " matching GIFT" : " matching GIFTs");
    } else if (section === "changelog") {
      var changeCount = filterChangelog(query);
      message = changeCount + (changeCount === 1 ? " matching change" : " matching changes");
    } else if (section === "schema") {
      var schemaCount = filterSchema(query);
      message = schemaCount + (schemaCount === 1 ? " matching table" : " matching tables");
    } else if (section === "tables") {
      var result = filterTables(query);
      message = result.rows + " rows in " + result.panels + (result.panels === 1 ? " table" : " tables");
    } else if (query) {
      activateView("gifts", true);
      return;
    }

    // An anchor filter narrows the list without any typed query, so the count
    // still needs announcing.
    var filtered = section === "gifts" && Boolean(anchorFilter("input") || anchorFilter("output"));
    if (announce && (query || filtered)) showStatus(message);
    if (!query && !filtered) status.classList.remove("visible");
  }

  buttons.forEach(function (button) {
    button.addEventListener("click", function () {
      activateView(button.getAttribute("data-view-button"), true);
    });
  });

  groupSelects.forEach(function (select) {
    select.addEventListener("change", function () {
      layoutGifts();
      applySearch(true);
    });
  });

  // The anchor lists are long, so each is a text field that narrows a dropdown
  // as the reader types. The committed anchor id lives in a hidden input, which
  // is what the table filter reads.
  var anchorCombos = Array.prototype.slice.call(
    document.querySelectorAll("[data-gift-combo]")
  ).map(function (root) {
    var field = root.querySelector("[data-gift-combo-input]");
    var list = root.querySelector(".combo-list");
    var empty = root.querySelector("[data-combo-empty]");
    var clear = root.querySelector("[data-gift-combo-clear]");
    var value = root.querySelector("[data-gift-anchor-filter]");
    var options = Array.prototype.slice.call(list.querySelectorAll("[role='option']"));
    var active = -1;

    function shown() {
      return options.filter(function (option) { return !option.hidden; });
    }

    function setActive(index) {
      var visible = shown();
      options.forEach(function (option) { option.classList.remove("active"); });
      active = index;
      if (index < 0 || index >= visible.length) {
        field.removeAttribute("aria-activedescendant");
        return;
      }
      var option = visible[index];
      option.classList.add("active");
      field.setAttribute("aria-activedescendant", option.id);
      if (typeof option.scrollIntoView === "function") {
        option.scrollIntoView({ block: "nearest" });
      }
    }

    function open() {
      list.hidden = false;
      field.setAttribute("aria-expanded", "true");
    }

    function close() {
      list.hidden = true;
      field.setAttribute("aria-expanded", "false");
      setActive(-1);
    }

    // A committed field reads "name \u00b7 ANCHOR_ID", so the query is matched as
    // separate words: editing that text keeps matching its own anchor.
    function narrow(query) {
      var words = query.toLowerCase().replace(/\u00b7/g, " ").split(/\s+/).filter(Boolean);
      var count = 0;
      options.forEach(function (option) {
        var haystack = option.getAttribute("data-search");
        var matches = words.every(function (word) { return haystack.indexOf(word) !== -1; });
        option.hidden = !matches;
        if (matches) count += 1;
      });
      empty.hidden = count > 0;
      setActive(-1);
      return count;
    }

    function label() {
      var selected = value.value;
      if (!selected) return "";
      var match = options.filter(function (option) {
        return option.getAttribute("data-value") === selected;
      })[0];
      return match ? match.getAttribute("data-label") : selected;
    }

    function commit(option) {
      value.value = option.getAttribute("data-value");
      field.value = option.getAttribute("data-label");
      options.forEach(function (other) {
        other.setAttribute("aria-selected", other === option ? "true" : "false");
      });
      clear.hidden = false;
      close();
      applySearch(true);
    }

    function reset(announce) {
      var had = Boolean(value.value);
      value.value = "";
      field.value = "";
      options.forEach(function (option) { option.setAttribute("aria-selected", "false"); });
      clear.hidden = true;
      narrow("");
      close();
      if (had && announce) applySearch(true);
      return had;
    }

    field.addEventListener("focus", function () {
      field.select();
      narrow("");
      open();
    });

    field.addEventListener("input", function () {
      narrow(field.value);
      open();
      // Emptying the field drops the filter rather than stranding a committed
      // anchor the reader can no longer see.
      if (!field.value && value.value) {
        value.value = "";
        clear.hidden = true;
        applySearch(true);
      }
    });

    field.addEventListener("keydown", function (event) {
      var visible = shown();
      if (event.key === "ArrowDown" || event.key === "ArrowUp") {
        event.preventDefault();
        if (list.hidden) {
          narrow(field.value);
          open();
        }
        if (!visible.length) return;
        var step = event.key === "ArrowDown" ? 1 : -1;
        var next = active === -1 ? (step === 1 ? 0 : visible.length - 1) : active + step;
        setActive((next + visible.length) % visible.length);
      } else if (event.key === "Enter") {
        if (list.hidden || !visible.length) return;
        event.preventDefault();
        commit(visible[active === -1 ? 0 : active]);
      } else if (event.key === "Escape") {
        event.stopPropagation();
        if (!list.hidden) {
          close();
        } else if (reset(true)) {
          return;
        }
      } else if (event.key === "Tab") {
        close();
      }
    });

    field.addEventListener("blur", function () {
      // Uncommitted text would misreport which anchor the table is filtered by.
      field.value = label();
      close();
    });

    // Committing runs on click, so the field must not lose focus first.
    list.addEventListener("mousedown", function (event) { event.preventDefault(); });

    list.addEventListener("click", function (event) {
      var node = event.target;
      while (node && node !== list && node.getAttribute("role") !== "option") {
        node = node.parentNode;
      }
      if (node && node !== list) commit(node);
    });

    clear.addEventListener("click", function () {
      reset(true);
      field.focus();
    });

    return { reset: reset };
  });

  if (resetAnchors) {
    resetAnchors.addEventListener("click", function () {
      anchorCombos.forEach(function (combo) { combo.reset(false); });
      applySearch(true);
    });
  }

  giftRows().forEach(function (row) {
    row.addEventListener("click", function () {
      openGift(row.getAttribute("data-gift-id"));
    });
    row.addEventListener("keydown", function (event) {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        openGift(row.getAttribute("data-gift-id"));
      }
    });
  });

  // A changelog entry names the GIFTs it affects; open the trait it refers to.
  Array.prototype.slice.call(document.querySelectorAll("[data-gift-link]")).forEach(function (link) {
    link.addEventListener("click", function () {
      var giftId = link.getAttribute("data-gift-link");
      // A stale query would leave the target row filtered out of the sequence
      // the modal arrows walk.
      search.value = "";
      activateView("gifts", true);
      openGift(giftId);
    });
  });

  Array.prototype.slice.call(modal.querySelectorAll("[data-gift-modal-close]")).forEach(function (control) {
    control.addEventListener("click", closeGift);
  });

  Array.prototype.slice.call(modal.querySelectorAll("[data-gift-step]")).forEach(function (control) {
    control.addEventListener("click", function () {
      stepGift(parseInt(control.getAttribute("data-gift-step"), 10));
    });
  });

  modal.addEventListener("keydown", function (event) {
    if (event.key === "Tab") {
      // Keep tabbing inside the dialog; the table behind it is inert while open.
      var focusable = Array.prototype.slice.call(
        modalWindow.querySelectorAll("button, a[href], summary, [tabindex]:not([tabindex='-1'])")
      ).filter(function (element) { return element.offsetParent !== null; });
      if (!focusable.length) return;
      var first = focusable[0];
      var last = focusable[focusable.length - 1];
      if (event.shiftKey && (document.activeElement === first || document.activeElement === modalWindow)) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
      return;
    }
    if (event.key === "ArrowLeft") {
      event.preventDefault();
      stepGift(-1);
    } else if (event.key === "ArrowRight") {
      event.preventDefault();
      stepGift(1);
    }
  });

  Array.prototype.slice.call(document.querySelectorAll("[data-graph-button]")).forEach(function (button) {
    button.addEventListener("click", function () {
      var name = button.getAttribute("data-graph-button");
      Array.prototype.slice.call(document.querySelectorAll("[data-graph-button]")).forEach(function (other) {
        var active = other === button;
        other.classList.toggle("active", active);
        other.setAttribute("aria-selected", active ? "true" : "false");
      });
      Array.prototype.slice.call(document.querySelectorAll("[data-graph-panel]")).forEach(function (panel) {
        panel.hidden = panel.getAttribute("data-graph-panel") !== name;
      });
    });
  });

  search.addEventListener("input", function () { applySearch(true); });
  search.addEventListener("keydown", function (event) {
    if (event.key === "Escape") {
      search.value = "";
      applySearch(false);
      search.blur();
    }
  });

  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape" && !modal.hidden) {
      event.preventDefault();
      closeGift();
      return;
    }
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
      event.preventDefault();
      search.focus();
      search.select();
    }
  });

  window.addEventListener("hashchange", function () {
    activateView(window.location.hash.replace(/^#/, "") || "overview", false);
  });

  // Browsers apply their native anchor scroll after inline scripts run. The
  // hash identifies an app view, not a vertical position, so keep its heading
  // below the sticky navigation on direct links such as report.html#schema.
  window.addEventListener("load", function () {
    window.scrollTo({ top: 0 });
  });

  // A reloaded page can restore a previously chosen grouping in the select.
  layoutGifts();
  activateView(window.location.hash.replace(/^#/, "") || "overview", false);
}());
