(function () {
  "use strict";

  var buttons = Array.prototype.slice.call(document.querySelectorAll("[data-view-button]"));
  var views = Array.prototype.slice.call(document.querySelectorAll("[data-view]"));
  var search = document.getElementById("global-search");
  var status = document.getElementById("search-status");
  var viewMenus = Array.prototype.slice.call(document.querySelectorAll("[data-view-menu]"));
  var statusTimer;

  function currentView() {
    var active = document.querySelector("[data-view].active");
    return active ? active.getAttribute("data-view") : "introduction";
  }

  // A route is a view name, optionally followed by an item within it: the
  // frames view gives each frame its own page at #frames/<frame_id>, and the
  // attempts view each expansion attempt at #attempts/<attempt_id>.
  function activateView(route, updateHash) {
    var parts = String(route).split("/");
    var name = parts[0];
    var item = parts.slice(1).join("/");
    var exists = views.some(function (view) {
      return view.getAttribute("data-view") === name;
    });
    if (!exists) {
      name = "introduction";
      item = "";
    }

    views.forEach(function (view) {
      view.classList.toggle("active", view.getAttribute("data-view") === name);
    });
    buttons.forEach(function (button) {
      var active = button.getAttribute("data-view-button") === name;
      button.classList.toggle("active", active);
      button.setAttribute("aria-current", active ? "page" : "false");
    });
    viewMenus.forEach(function (menu) {
      var active = Boolean(menu.querySelector('[data-view-button="' + name + '"]'));
      var summary = menu.querySelector("summary");
      summary.classList.toggle("active", active);
      summary.setAttribute("aria-current", active ? "page" : "false");
    });
    if (updateHash && window.history && window.history.replaceState) {
      window.history.replaceState(null, "", "#" + name + (item ? "/" + item : ""));
    }
    showFrame(name === "frames" ? item : "");
    showAttempt(name === "attempts" ? item : "");
    applySearch(false);
    // The GIFT page is opened after the filters run, so its position counts the
    // rows they keep.
    if (name === "gifts" && item) openGift(item);
    else closeGift();
    updateBreadcrumbs(name, item);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  // gifter > menu > section, and the open GIFT, frame or attempt when there is
  // one. The section is named as its menu names it: most views sit under Atlas,
  // the expansion attempts under Curation.
  var breadcrumbs = document.querySelector("[data-breadcrumbs]");

  function crumb(label, href) {
    var item = document.createElement("li");
    if (href) {
      var link = document.createElement("a");
      link.href = href;
      link.textContent = label;
      item.appendChild(link);
    } else {
      item.textContent = label;
      item.setAttribute("aria-current", "page");
    }
    return item;
  }

  function updateBreadcrumbs(name, item) {
    if (!breadcrumbs) return;
    var button = document.querySelector('[data-view-menu] [data-view-button="' + name + '"]');
    var leaf = "";
    if (item && name === "gifts") {
      var gift = openGiftPage();
      if (gift) leaf = gift.getAttribute("data-gift-name") || gift.getAttribute("data-gift-id");
    } else if (item && (name === "frames" || name === "attempts")) {
      var page = name === "frames" ? openFramePage() : openAttemptPage();
      var heading = page && page.querySelector("h2");
      if (heading) leaf = heading.textContent;
    }
    var menu = button && button.closest("[data-view-menu]");
    var summary = menu && menu.querySelector("summary");
    var trail = [
      crumb("gifter", breadcrumbs.getAttribute("data-home")),
      crumb(
        summary ? summary.textContent : "Atlas",
        (menu && menu.getAttribute("data-menu-home")) || "#introduction"
      ),
      crumb(button ? button.textContent : name, leaf ? "#" + name : null)
    ];
    if (leaf) trail.push(crumb(leaf, null));
    breadcrumbs.replaceChildren.apply(breadcrumbs, trail);
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

  var giftView = document.querySelector('[data-view="gifts"]');
  var giftList = giftView.querySelector("[data-gift-list]");
  var giftPages = giftView.querySelector("[data-gift-pages]");
  var giftPosition = giftPages.querySelector("[data-gift-position]");

  function giftRows() {
    return Array.prototype.slice.call(
      document.querySelectorAll('[data-view="gifts"] [data-gift-row]')
    );
  }

  // Navigation steps through everything the current filters keep, not only the
  // page on screen, so the arrows walk the whole result and turn the page when
  // they reach its edge.
  function visibleGiftRows() {
    if (giftFiltered) return giftFiltered;
    return giftRows().filter(function (row) { return !row.hidden; });
  }

  function openGiftPage() {
    if (giftPages.hidden) return null;
    return giftPages.querySelector("[data-gift-detail]:not([hidden])");
  }

  // Show one GIFT's page in place of the catalogue. Navigation goes through the
  // address, #gifts/<gift_id>, so a page can be linked to and the browser's
  // back button returns to the table.
  function openGift(giftId) {
    var detail = giftPages.querySelector('[data-gift-detail][data-gift-id="' + giftId + '"]');
    if (!detail) {
      closeGift();
      return;
    }

    giftRows().forEach(function (row) {
      var selected = row.getAttribute("data-gift-id") === giftId;
      row.classList.toggle("selected", selected);
      row.setAttribute("aria-selected", selected ? "true" : "false");
    });
    Array.prototype.slice.call(giftPages.querySelectorAll("[data-gift-detail]")).forEach(function (other) {
      other.hidden = other !== detail;
    });

    var visible = visibleGiftRows();
    var position = -1;
    visible.forEach(function (row, index) {
      if (row.getAttribute("data-gift-id") === giftId) position = index;
    });
    giftPosition.textContent = position === -1 ? "" : (position + 1) + " / " + visible.length;

    giftList.hidden = true;
    giftPages.hidden = false;
    setEmptyState(giftView, false);
  }

  function closeGift() {
    giftPages.hidden = true;
    giftList.hidden = false;
  }

  function goToGift(giftId) {
    window.location.hash = "gifts/" + giftId;
  }

  function stepGift(offset) {
    var open = openGiftPage();
    if (!open) return;
    var visible = visibleGiftRows();
    var current = -1;
    visible.forEach(function (row, index) {
      if (row.getAttribute("data-gift-id") === open.getAttribute("data-gift-id")) current = index;
    });
    if (current === -1 || !visible.length) return;
    var next = (current + offset + visible.length) % visible.length;
    // The table follows along, so going back lands on the page holding the
    // GIFT last shown.
    showGiftPage(pageOf(next));
    goToGift(visible[next].getAttribute("data-gift-id"));
  }

  // Frame pages carry GIFT tables of their own, so the explorer's table is
  // found within its view.
  var giftBody = document.querySelector('[data-view="gifts"] .gift-summary-table tbody');
  var giftTable = document.querySelector('[data-view="gifts"] .gift-summary-table');
  // The curated order the table ships in. Sorting reorders a copy, so clearing
  // a sort restores it rather than approximating it.
  var giftCurated = giftRows();
  var giftOrder = giftCurated.slice();
  var groupSelects = [
    document.querySelector("[data-gift-group-select]"),
    document.querySelector("[data-gift-group-select-2]")
  ].filter(Boolean);
  var resetAnchors = document.querySelector("[data-gift-reset]");
  var collapsedGroups = {};

  // Paging state. `giftFiltered` is every row the filters keep, in the order
  // they are laid out; the page is a window onto it.
  var pager = document.querySelector("[data-gift-pager]");
  var pageSizeSelect = pager ? pager.querySelector("[data-gift-page-size]") : null;
  var pagerStatus = pager ? pager.querySelector("[data-gift-pager-status]") : null;
  var pagerPages = pager ? pager.querySelector("[data-gift-pager-pages]") : null;
  var giftFiltered = null;
  var giftPageSize = pageSizeSelect ? Number(pageSizeSelect.value) || 20 : 20;
  var giftPage = 1;
  var giftSignature = null;

  // Sorting state: the column being sorted and its direction. A column cycles
  // ascending, descending, then back to the curated order.
  var sortHeaders = Array.prototype.slice.call(
    giftTable.querySelectorAll("[data-gift-sort]")
  );
  var sortColumn = "";
  var sortDirection = 0;

  // The key lives in the cell under the header that was clicked, so a column
  // needs no separate lookup table: the header says which element holds it and
  // how to compare it.
  function sortKey(row, header) {
    var cell = row.cells[header.parentNode.cellIndex];
    if (!cell) return "";
    var select = header.getAttribute("data-sort-select");
    var source = select ? cell.querySelector(select) || cell : cell;
    var text = (source.textContent || "").trim();
    if (header.getAttribute("data-sort-type") === "number") {
      var value = parseFloat(text);
      return isNaN(value) ? -Infinity : value;
    }
    return text.toLowerCase();
  }

  function sortGifts() {
    var header = sortColumn && sortDirection
      ? giftTable.querySelector('[data-gift-sort="' + sortColumn + '"]')
      : null;
    giftOrder = giftCurated.slice();
    if (header) {
      // The sort is stable, so rows that compare equal stay in curated order.
      giftOrder.sort(function (left, right) {
        var a = sortKey(left, header);
        var b = sortKey(right, header);
        if (a === b) return 0;
        return (a < b ? -1 : 1) * sortDirection;
      });
    }
    sortHeaders.forEach(function (other) {
      var active = other === header;
      if (active) {
        other.setAttribute("data-sort-direction", sortDirection > 0 ? "asc" : "desc");
      } else {
        other.removeAttribute("data-sort-direction");
      }
      other.parentNode.setAttribute(
        "aria-sort", active ? (sortDirection > 0 ? "ascending" : "descending") : "none"
      );
    });
  }

  function pageOf(index) {
    return Math.floor(index / giftPageSize) + 1;
  }

  // The upper bound depends on how many rows survive the filters, so it is
  // clamped while they are applied; only the floor is known here.
  function showGiftPage(page) {
    var target = Math.max(1, page);
    if (target === giftPage) return;
    giftPage = target;
    applySearch(false);
  }

  // A narrower result set can leave the reader on a page that no longer
  // exists, so filtering always starts the list over at the top.
  function resetGiftPage() {
    giftPage = 1;
  }

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
  // than duplicating it: one node per GIFT keeps selection and the page in sync.
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

  // Right-clicking a group header offers whole-table expand and collapse, so a
  // deeply grouped table can be folded without clicking every header in turn.
  var groupMenu = null;

  function closeGroupMenu() {
    if (groupMenu) groupMenu.hidden = true;
  }

  // Collapsing acts on the headers currently laid out, so a second grouping
  // axis folds away with the first rather than reappearing when expanded.
  function setAllGroups(collapsed) {
    collapsedGroups = {};
    if (collapsed) {
      groupRows().forEach(function (row) {
        collapsedGroups[row.getAttribute("data-gift-group")] = true;
      });
    }
    applySearch(false);
  }

  function buildGroupMenu() {
    var menu = document.createElement("div");
    menu.className = "gift-group-menu";
    menu.setAttribute("role", "menu");
    menu.hidden = true;
    [
      { label: "Expand all groups", collapsed: false },
      { label: "Collapse all groups", collapsed: true }
    ].forEach(function (item) {
      var button = document.createElement("button");
      button.type = "button";
      button.setAttribute("role", "menuitem");
      button.textContent = item.label;
      button.addEventListener("click", function () {
        closeGroupMenu();
        setAllGroups(item.collapsed);
      });
      menu.appendChild(button);
    });
    document.body.appendChild(menu);
    return menu;
  }

  function openGroupMenu(x, y) {
    if (!groupMenu) groupMenu = buildGroupMenu();
    groupMenu.hidden = false;
    // The size is only measurable once shown, so a menu opened near an edge is
    // pulled back inside the viewport rather than being clipped by it.
    var width = groupMenu.offsetWidth;
    var height = groupMenu.offsetHeight;
    groupMenu.style.left = Math.max(4, Math.min(x, window.innerWidth - width - 4)) + "px";
    groupMenu.style.top = Math.max(4, Math.min(y, window.innerHeight - height - 4)) + "px";
    groupMenu.querySelector("button").focus();
  }

  giftBody.addEventListener("contextmenu", function (event) {
    var target = event.target;
    var row = target && target.closest ? target.closest(".gift-group-row") : null;
    if (!row) return;
    event.preventDefault();
    // The keyboard menu key reports no pointer position, so the menu then opens
    // against the header itself.
    var rect = row.getBoundingClientRect();
    var x = event.clientX || rect.left + 12;
    var y = event.clientY || rect.bottom;
    openGroupMenu(x, y);
  });

  document.addEventListener("mousedown", function (event) {
    if (!groupMenu || groupMenu.hidden) return;
    if (!groupMenu.contains(event.target)) closeGroupMenu();
  });

  window.addEventListener("resize", closeGroupMenu);
  window.addEventListener("scroll", closeGroupMenu, true);

  function filterGifts(query) {
    var view = document.querySelector('[data-view="gifts"]');
    var grouped = isGrouped();
    var input = anchorFilter("input");
    var output = anchorFilter("output");
    var matched = {};
    var onPage = {};
    var count = 0;
    var keyed = [];

    giftFiltered = [];
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
      row.hidden = true;
      if (matches && !(grouped && withinCollapsed)) {
        giftFiltered.push(row);
        keyed.push(keys);
      }
    });

    // Only the rows a reader could actually see are paged: a collapsed group
    // keeps its header on every page but spends no room on it.
    var pages = Math.max(1, Math.ceil(giftFiltered.length / giftPageSize));
    if (giftPage > pages) giftPage = pages;
    var start = (giftPage - 1) * giftPageSize;
    var end = Math.min(start + giftPageSize, giftFiltered.length);
    giftFiltered.forEach(function (row, index) {
      var shown = index >= start && index < end;
      row.hidden = !shown;
      if (shown) {
        keyed[index].forEach(function (key) { onPage[key] = (onPage[key] || 0) + 1; });
      }
    });

    groupRows().forEach(function (row) {
      var key = row.getAttribute("data-gift-group");
      var total = matched[key] || 0;
      // An empty group disappears, a subgroup also disappears while an ancestor
      // is collapsed, and an expanded group whose rows all sit on another page
      // goes with them.
      row.hidden = total === 0 || ancestorCollapsed(key) ||
        (!collapsedGroups[key] && !onPage[key]);
      var toggle = row.querySelector("[data-gift-group-toggle]");
      toggle.setAttribute("aria-expanded", collapsedGroups[key] ? "false" : "true");
      toggle.querySelector("small").textContent = total + (total === 1 ? " GIFT" : " GIFTs");
    });

    renderPager(start, end, pages);
    if (resetAnchors) resetAnchors.hidden = !input && !output;
    setEmptyState(view, count === 0);
    return count;
  }

  function renderPager(start, end, pages) {
    if (!pager) return;
    var total = giftFiltered.length;
    pager.hidden = total === 0;
    pagerStatus.textContent = total === 0
      ? "No GIFTs"
      : "Showing " + (start + 1) + "\u2013" + end + " of " + total;
    pagerPages.textContent = "Page " + giftPage + " of " + pages;
    Array.prototype.slice.call(pager.querySelectorAll("[data-gift-page-step]"))
      .forEach(function (button) {
        var step = Number(button.getAttribute("data-gift-page-step"));
        button.disabled = giftPage + step < 1 || giftPage + step > pages;
      });
  }

  var frameFilter = "all";
  var frameButtons = Array.prototype.slice.call(
    document.querySelectorAll("[data-frame-filter]")
  );

  var frameView = document.querySelector('[data-view="frames"]');
  var frameList = frameView.querySelector("[data-frame-list]");
  var framePages = Array.prototype.slice.call(frameView.querySelectorAll("[data-frame-page]"));

  function openFramePage() {
    return framePages.filter(function (page) { return !page.hidden; })[0] || null;
  }

  // The table and a frame's page are alternatives: an unknown or empty id
  // shows the table.
  function showFrame(frameId) {
    var target = null;
    framePages.forEach(function (page) {
      var match = Boolean(frameId) && page.getAttribute("data-frame-id") === frameId;
      page.hidden = !match;
      if (match) target = page;
    });
    frameList.hidden = Boolean(target);
    if (target) setEmptyState(frameView, false);
  }

  function filterFrames(query) {
    var rows = Array.prototype.slice.call(frameView.querySelectorAll("[data-frame-row]"));
    var count = 0;
    rows.forEach(function (row) {
      var textMatches = !query || row.getAttribute("data-search").indexOf(query) !== -1;
      var filterMatches = frameFilter === "all" ||
        (frameFilter === "bounded" && row.getAttribute("data-frame-bounded") === "true") ||
        row.getAttribute("data-frame-scopes").indexOf(" " + frameFilter + " ") !== -1;
      var matches = textMatches && filterMatches;
      row.hidden = !matches;
      if (matches) count += 1;
    });
    setEmptyState(frameView, !openFramePage() && count === 0);
    return count;
  }

  Array.prototype.slice.call(frameView.querySelectorAll("[data-frame-row]")).forEach(function (row) {
    function open() {
      window.location.hash = "frames/" + row.getAttribute("data-frame-id");
    }
    row.addEventListener("click", open);
    row.addEventListener("keydown", function (event) {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        open();
      }
    });
  });

  Array.prototype.slice.call(frameView.querySelectorAll("[data-frame-back]")).forEach(function (button) {
    button.addEventListener("click", function () {
      window.location.hash = "frames";
    });
  });

  var attemptFilter = "all";
  var attemptButtons = Array.prototype.slice.call(
    document.querySelectorAll("[data-attempt-filter]")
  );
  var attemptView = document.querySelector('[data-view="attempts"]');
  var attemptList = attemptView.querySelector("[data-attempt-list]");
  var attemptPages = Array.prototype.slice.call(attemptView.querySelectorAll("[data-attempt-page]"));

  function openAttemptPage() {
    return attemptPages.filter(function (page) { return !page.hidden; })[0] || null;
  }

  // As with frames, the table and an attempt's page are alternatives.
  function showAttempt(attemptId) {
    var target = null;
    attemptPages.forEach(function (page) {
      var match = Boolean(attemptId) && page.getAttribute("data-attempt-id") === attemptId;
      page.hidden = !match;
      if (match) target = page;
    });
    attemptList.hidden = Boolean(target);
    if (target) setEmptyState(attemptView, false);
  }

  function filterAttempts(query) {
    var rows = Array.prototype.slice.call(attemptView.querySelectorAll("[data-attempt-row]"));
    var count = 0;
    rows.forEach(function (row) {
      var textMatches = !query || row.getAttribute("data-search").indexOf(query) !== -1;
      var filterMatches = attemptFilter === "all" ||
        row.getAttribute("data-attempt-outcomes").indexOf(" " + attemptFilter + " ") !== -1;
      var matches = textMatches && filterMatches;
      row.hidden = !matches;
      if (matches) count += 1;
    });
    setEmptyState(attemptView, !openAttemptPage() && count === 0);
    return count;
  }

  Array.prototype.slice.call(attemptView.querySelectorAll("[data-attempt-row]")).forEach(function (row) {
    function open() {
      window.location.hash = "attempts/" + row.getAttribute("data-attempt-id");
    }
    row.addEventListener("click", open);
    row.addEventListener("keydown", function (event) {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        open();
      }
    });
  });

  Array.prototype.slice.call(attemptView.querySelectorAll("[data-attempt-back]")).forEach(function (button) {
    button.addEventListener("click", function () {
      window.location.hash = "attempts";
    });
  });

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
      // Any change to what is being filtered for starts the list over at the
      // top; turning a page or folding a group leaves the reader where they are.
      var signature = [
        query, anchorFilter("input"), anchorFilter("output"), groupAxes().join("|"),
        sortColumn + sortDirection
      ].join(SEPARATOR);
      if (signature !== giftSignature) {
        giftSignature = signature;
        resetGiftPage();
      }
      var giftCount = filterGifts(query);
      message = giftCount + (giftCount === 1 ? " matching GIFT" : " matching GIFTs");
    } else if (section === "frames") {
      var frameCount = filterFrames(query);
      message = frameCount +
        (frameCount === 1 ? " matching frame" : " matching frames");
    } else if (section === "attempts") {
      var attemptCount = filterAttempts(query);
      message = attemptCount +
        (attemptCount === 1 ? " matching attempt" : " matching attempts");
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
    var filtered = (section === "gifts" && Boolean(anchorFilter("input") || anchorFilter("output"))) ||
      (section === "frames" && frameFilter !== "all") ||
      (section === "attempts" && attemptFilter !== "all");
    if (announce && (query || filtered)) showStatus(message);
    if (!query && !filtered) status.classList.remove("visible");
  }

  buttons.forEach(function (button) {
    button.addEventListener("click", function () {
      activateView(button.getAttribute("data-view-button"), true);
      var menu = button.closest("[data-view-menu]");
      if (menu) menu.removeAttribute("open");
    });
  });

  // The header dropdowns are <details> elements, which stay open until their
  // summary is clicked again; a click anywhere else closes them too.
  document.addEventListener("click", function (event) {
    Array.prototype.forEach.call(document.querySelectorAll(".site-menu[open]"), function (menu) {
      if (!menu.contains(event.target)) menu.removeAttribute("open");
    });
  });

  frameButtons.forEach(function (button) {
    button.addEventListener("click", function () {
      frameFilter = button.getAttribute("data-frame-filter");
      frameButtons.forEach(function (other) {
        var active = other === button;
        other.classList.toggle("active", active);
        other.setAttribute("aria-pressed", active ? "true" : "false");
      });
      applySearch(true);
    });
  });

  attemptButtons.forEach(function (button) {
    button.addEventListener("click", function () {
      attemptFilter = button.getAttribute("data-attempt-filter");
      attemptButtons.forEach(function (other) {
        var active = other === button;
        other.classList.toggle("active", active);
        other.setAttribute("aria-pressed", active ? "true" : "false");
      });
      applySearch(true);
    });
  });

  groupSelects.forEach(function (select) {
    select.addEventListener("change", function () {
      layoutGifts();
      applySearch(true);
    });
  });

  sortHeaders.forEach(function (header) {
    header.addEventListener("click", function () {
      var column = header.getAttribute("data-gift-sort");
      if (column !== sortColumn) {
        sortColumn = column;
        sortDirection = 1;
      } else {
        sortDirection = sortDirection === 1 ? -1 : 0;
        if (!sortDirection) sortColumn = "";
      }
      sortGifts();
      layoutGifts();
      applySearch(false);
    });
  });

  if (pageSizeSelect) {
    pageSizeSelect.addEventListener("change", function () {
      // The reader keeps their place rather than their page number: the new
      // page is the one holding the row that headed the old one.
      var first = (giftPage - 1) * giftPageSize;
      giftPageSize = Number(pageSizeSelect.value) || 20;
      giftPage = Math.floor(first / giftPageSize) + 1;
      applySearch(false);
    });
  }

  if (pager) {
    Array.prototype.slice.call(pager.querySelectorAll("[data-gift-page-step]"))
      .forEach(function (button) {
        button.addEventListener("click", function () {
          showGiftPage(giftPage + Number(button.getAttribute("data-gift-page-step")));
        });
      });
  }

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
      goToGift(row.getAttribute("data-gift-id"));
    });
    row.addEventListener("keydown", function (event) {
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        goToGift(row.getAttribute("data-gift-id"));
      }
    });
  });

  // A changelog entry names the GIFTs it affects, and a frame page lists its
  // members; either opens the trait it refers to.
  Array.prototype.slice.call(document.querySelectorAll("[data-gift-link]")).forEach(function (link) {
    function open() {
      // A stale query would leave the target row filtered out of the sequence
      // the page arrows walk.
      search.value = "";
      goToGift(link.getAttribute("data-gift-link"));
    }
    link.addEventListener("click", open);
    if (link.tagName === "TR") {
      link.addEventListener("keydown", function (event) {
        if (event.key === "Enter" || event.key === " ") {
          event.preventDefault();
          open();
        }
      });
    }
  });

  giftPages.querySelector("[data-gift-back]").addEventListener("click", function () {
    window.location.hash = "gifts";
  });

  Array.prototype.slice.call(giftPages.querySelectorAll("[data-gift-step]")).forEach(function (control) {
    control.addEventListener("click", function () {
      stepGift(parseInt(control.getAttribute("data-gift-step"), 10));
    });
  });

  // The overview networks draw no labels, so every fact about a dot is read
  // out of its data attributes into one hover card. Pointing at a dot also
  // dims everything it is not connected to, which is the only way to follow a
  // single trait through a few hundred crossing edges.
  Array.prototype.slice.call(document.querySelectorAll("[data-dot-network]")).forEach(function (frame) {
    var tooltip = frame.querySelector("[data-dot-tooltip]");
    var dots = Array.prototype.slice.call(frame.querySelectorAll(".dot-node"));
    var edges = Array.prototype.slice.call(frame.querySelectorAll(".dot-edge"));
    var neighbours = {};

    edges.forEach(function (edge) {
      var from = edge.getAttribute("data-edge-from");
      var to = edge.getAttribute("data-edge-to");
      (neighbours[from] = neighbours[from] || {})[to] = true;
      (neighbours[to] = neighbours[to] || {})[from] = true;
    });

    function add(parent, tag, text) {
      var element = document.createElement(tag);
      if (text !== undefined) element.textContent = text;
      parent.appendChild(element);
      return element;
    }

    // The card is built out of text nodes rather than markup, so a curated
    // name carrying an ampersand or an angle bracket is printed, not parsed.
    function describe(dot) {
      while (tooltip.firstChild) tooltip.removeChild(tooltip.firstChild);
      add(tooltip, "b", dot.getAttribute("data-node-label"));
      add(tooltip, "code", dot.getAttribute("data-node-sublabel"));
      var lines = (dot.getAttribute("data-node-detail") || "").split("\n").filter(Boolean);
      if (lines.length) {
        var list = add(tooltip, "ul");
        lines.forEach(function (line) {
          var item = add(list, "li");
          var split = line.indexOf("|");
          if (split === -1) {
            item.textContent = line;
            return;
          }
          add(item, "span", line.slice(0, split));
          item.appendChild(document.createTextNode(line.slice(split + 1)));
        });
      }
      if (dot.getAttribute("data-node-gift")) add(tooltip, "em", "Click to open this GIFT");
    }

    function place(dot) {
      var frameBox = frame.getBoundingClientRect();
      var dotBox = dot.getBoundingClientRect();
      var left = dotBox.left - frameBox.left + dotBox.width / 2 + 14;
      var top = dotBox.top - frameBox.top + dotBox.height / 2 + 14;
      // Flip the card back inside the frame rather than letting it spill over
      // the edge of the drawing.
      if (left + tooltip.offsetWidth > frameBox.width - 8) {
        left = Math.max(8, left - tooltip.offsetWidth - 28);
      }
      if (top + tooltip.offsetHeight > frameBox.height - 8) {
        top = Math.max(8, top - tooltip.offsetHeight - 28);
      }
      tooltip.style.left = Math.round(left) + "px";
      tooltip.style.top = Math.round(top) + "px";
    }

    function probe(dot) {
      var id = dot.getAttribute("data-node-id");
      var near = neighbours[id] || {};
      dots.forEach(function (other) {
        var otherId = other.getAttribute("data-node-id");
        other.classList.toggle("near", other === dot || near[otherId] === true);
        other.classList.toggle("active", other === dot);
      });
      edges.forEach(function (edge) {
        edge.classList.toggle(
          "near",
          edge.getAttribute("data-edge-from") === id || edge.getAttribute("data-edge-to") === id
        );
      });
      frame.classList.add("probing");
      describe(dot);
      tooltip.hidden = false;
      tooltip.setAttribute("aria-hidden", "false");
      place(dot);
    }

    function clearProbe() {
      frame.classList.remove("probing");
      dots.forEach(function (dot) { dot.classList.remove("near", "active"); });
      edges.forEach(function (edge) { edge.classList.remove("near"); });
      tooltip.hidden = true;
      tooltip.setAttribute("aria-hidden", "true");
    }

    function openDot(dot) {
      var giftId = dot.getAttribute("data-node-gift");
      if (!giftId) return;
      // A stale query would leave the target row filtered out of the sequence
      // the page arrows walk.
      search.value = "";
      clearProbe();
      goToGift(giftId);
    }

    dots.forEach(function (dot) {
      dot.addEventListener("mouseenter", function () { probe(dot); });
      dot.addEventListener("focus", function () { probe(dot); });
      dot.addEventListener("blur", clearProbe);
      dot.addEventListener("click", function () { openDot(dot); });
      dot.addEventListener("keydown", function (event) {
        if (event.key === "Enter" || event.key === " ") {
          event.preventDefault();
          openDot(dot);
        }
      });
    });
    frame.addEventListener("mouseleave", clearProbe);

    // Colouring by metadata is a repaint: every dot already carries the colour
    // each scheme would give it, so the menus only choose which attribute wins.
    var legend = frame.querySelector("[data-dot-legend]");
    var menus = Array.prototype.slice.call(
      document.querySelectorAll("[data-colour-by]")
    );
    function repaint() {
      var chosen = {};
      menus.forEach(function (menu) {
        chosen[menu.getAttribute("data-colour-by")] = menu.value;
      });
      dots.forEach(function (dot) {
        var family = dot.classList.contains("gift") ? "gift" : "anchor";
        var scheme = chosen[family] || "";
        var core = dot.querySelector(".dot-core");
        var fill = scheme ? dot.getAttribute("data-fill-" + scheme) : "";
        core.style.fill = fill || "";
        // No colour for this dot under this scheme: the palette is never
        // cycled, so it is drawn as a ring instead of as an eighth hue.
        dot.classList.toggle("unassigned", Boolean(scheme) && !fill);
      });
      if (!legend) return;
      Array.prototype.slice.call(
        legend.querySelectorAll("[data-legend]")
      ).forEach(function (block) {
        var name = block.getAttribute("data-legend").split(":");
        block.hidden = (chosen[name[0]] || "") !== name[1];
      });
    }
    menus.forEach(function (menu) { menu.addEventListener("change", repaint); });
    repaint();
  });

  search.addEventListener("input", function () {
    if (currentView() === "frames" && openFramePage()) {
      activateView("frames", true);
      return;
    }
    if (currentView() === "gifts" && openGiftPage()) {
      activateView("gifts", true);
      return;
    }
    applySearch(true);
  });
  search.addEventListener("keydown", function (event) {
    if (event.key === "Escape") {
      search.value = "";
      applySearch(false);
      search.blur();
    }
  });

  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape" && groupMenu && !groupMenu.hidden) {
      event.preventDefault();
      closeGroupMenu();
      return;
    }
    // On a GIFT page the arrow keys step through the filtered GIFTs, unless
    // the reader is typing or choosing in a form control.
    var target = event.target;
    var typing = target && /^(INPUT|SELECT|TEXTAREA)$/.test(target.tagName);
    if (!typing && currentView() === "gifts" && openGiftPage() &&
        (event.key === "ArrowLeft" || event.key === "ArrowRight") &&
        !event.metaKey && !event.ctrlKey && !event.altKey) {
      event.preventDefault();
      stepGift(event.key === "ArrowLeft" ? -1 : 1);
      return;
    }
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") {
      event.preventDefault();
      search.focus();
      search.select();
    }
  });

  window.addEventListener("hashchange", function () {
    activateView(window.location.hash.replace(/^#/, "") || "introduction", false);
  });

  // Browsers apply their native anchor scroll after inline scripts run. The
  // hash identifies an app view, not a vertical position, so keep its heading
  // below the sticky navigation on direct links such as report.html#schema.
  window.addEventListener("load", function () {
    window.scrollTo({ top: 0 });
  });

  // A reloaded page can restore a previously chosen grouping in the select.
  sortGifts();
  layoutGifts();
  activateView(window.location.hash.replace(/^#/, "") || "introduction", false);
}());
