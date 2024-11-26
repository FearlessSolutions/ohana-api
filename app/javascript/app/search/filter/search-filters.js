// Handles search filter functionality.
import TextInput from './TextInput';
import map from '../../result/result-map';
import { initializeMapToggle } from '../../util/map/map_toggle';

// The search filters.
var _keyword;
var _agency;

// The form to submit.
var _searchForm;

var _categorySelect;

// The number of search options selected for filter count on smaller screens
let appliedSearchOptionsCount = 0;

// Main module initialization.
function init() {

  // Set up text input filters
  _keyword = TextInput.create('keyword-search-box');
  _agency = TextInput.create('org-name-options');

  // Capture form submission.
  _searchForm = document.getElementById('form-search');

  // Add on change function for category dropdown menu
  _categorySelect = document.getElementById('main_category');
  if (_categorySelect) {
    _categorySelect.addEventListener('change', _updateSubCategories, false);
  }

  var checkboxes = $('#categories input');

  var currentCheckbox;
  for (var i=0; i < checkboxes.length; i++) {
    currentCheckbox = checkboxes[i];
    _checkState('depth',0,currentCheckbox);
  }

  var curr;
  for (var l = 0; l < checkboxes.length; l += 1) {
    curr = checkboxes[l];
    $(curr).click(_linkClickedHandler);
  }

  var parentFilterHeaders = document.getElementsByClassName('parent-category-label-container');
  for (var l = 0; l < parentFilterHeaders.length; l += 1) {
    curr = parentFilterHeaders[l];
    curr.addEventListener('click', _handleHeaderClick, false);
    curr.addEventListener('keydown', _handleHeaderClick, false);
  }

  _openCheckedSections();

  $("#reset-filters-button").click(e => _resetFilters(e));

  $("#button-geolocate").click(e => {
    _getCurrentLocation(e);
    updateAppliedSearchOptionsCount();
  });

  $("#form-search").change(e => {
    _handleFormChange(e);
    updateAppliedSearchOptionsCount();
  });

  $("#keyword").on('input', debounce(() => {
    updateAppliedSearchOptionsCount();
  }, 500));

  $("#address").on('input', debounce(() => {
    updateAppliedSearchOptionsCount();
  }, 500));

}

var debounce = function (func, wait, immediate) {
  var timeout;
  return function() {
      var context = this, args = arguments;
      var later = function() {
              timeout = null;
              if (!immediate) func.apply(context, args);
      };
      var callNow = immediate && !timeout;
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
      if (callNow) func.apply(context, args);
  };
};

function _handleFormChange(e){

  if (e.target.type == "text" || e.target.type == "search"){ return; }

  if (e.target.id == "main_category"){
    //if main category was changed clear subcategories before form submit
    $( "input[name='categories[]']" ).prop('checked', false);
  };

  if ($("#address").val() != "Current Location"){
    $('#button-geolocate').removeClass('geolocated');
  }
}

function _getCurrentLocation(e){

  var options = {
    enableHighAccuracy: false,
    timeout: 20000,
    maximumAge: 9999999
  };

  function success(pos) {
    let crd = pos.coords;
    $('#lat').val(crd.latitude);
    $('#long').val(crd.longitude);
    $("#bar").hide();
  };

  function error(err) {
    console.warn(`ERROR(${err.code}): ${err.message}`);
  }

  var i = 0;
  function moveLoadingBar() {
    if (i == 0) {
      i = 1;
      var elem = document.getElementById("bar");
      var width = 1;
      var id = setInterval(frame, 30);
      function frame() {
        if (width >= 100) {
          clearInterval(id);
          i = 0;
        } else {
          width++;
          elem.style.width = width + "%";
        }
      }
    }
  }


  e.preventDefault();
  $('#address').val('Current Location');
  $('#button-geolocate').addClass('geolocated');
  $('#bar').show();
  moveLoadingBar();
  navigator.geolocation.getCurrentPosition(success, error, options);

}

function _resetFilters(e){
  e.preventDefault();
  $(':input').each(function() {
    // don't clear the keyword field
    if ($(this).attr("id") != "keyword") {
      $(this).val("");
    }
  });

  const url = new URL(window.location.href);
  url.searchParams.delete('main_category');
  url.searchParams.delete('languages');
  window.history.replaceState({}, '', url.toString());

  _updateSubCategories();
  updateAppliedSearchOptionsCount();
  _getSearchResults(e);
}

function _getSearchResults(e){

  var formData = $("#form-filters").serialize();
  const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

    $.ajax({
      type: 'GET',
      url: '/locations',
      headers: {
        'X-CSRF-Token': csrfToken,
        'accept':"text/html"
      },
      data: formData + "&layout=false&form=true",
      success: function(response) {
        $("#results-container").empty();
        $("#results-container").append(response);

        if ( $("#map-view").length ){
          map.init();
        }

        //remove layout=false from pagination hrefs
        $('nav a').each(function(){
            var oldUrl = $(this).attr("href");
            var newUrl = oldUrl.replace("&layout=false", "");
            $(this).attr("href", newUrl);
        });
      }
    });
}




function _updateSubCategories(){
  var selectedCategoryName = _categorySelect.value;
  var subCategoriesFilterTitleElement = document.getElementById('subcategoriesFilterTitle');
  var iconContainer = document.getElementById('iconContainer');
  var filterDropdownContainer = document.getElementById('filterDropdownContainer');
  var subcategoriesListContainerElement = document.getElementById('subcategoriesList');
  var categoriesFiltersContainer = document.getElementById('categoryFiltersContainerDiv');
  var subcategoriesFilterTitle = document.getElementById('subcategoriesFilterTitle');
  var parentCategoryDiv = document.getElementById('parent-category');

  if (selectedCategoryName == ""){

    subCategoriesFilterTitleElement.textContent = "Select a Topic from above to display additional filters.";
    subcategoriesFilterTitle.classList.remove("parent-category-label");
    subcategoriesListContainerElement.innerHTML = "";
    iconContainer.classList.remove("fa");
    iconContainer.classList.remove("fa-chevron-down");
    iconContainer.classList.remove("fa-chevron-right");
    parentCategoryDiv.classList.remove("hoverable");
    parentCategoryDiv.setAttribute("aria-label", "Select a Topic from above to display additional filters.");
    parentCategoryDiv.setAttribute("aria-expanded", "false");

  }else{

    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

    $.ajax({
      type: 'POST',
      url: '/locations/get_subcategories_by_category',
      dataType: 'json',
      headers: {
        'X-CSRF-Token': csrfToken,
      },
      data: {
        category_name : selectedCategoryName,
      },
      success: function(data) {

        subCategoriesFilterTitleElement.textContent = data.category_title;

        iconContainer.classList.add("fa");
        iconContainer.classList.remove("fa-chevron-down");
        iconContainer.classList.add("fa-chevron-down");

        subcategoriesFilterTitle.classList.add("parent-category-label");

        parentCategoryDiv.classList.add("hoverable");
        parentCategoryDiv.setAttribute("aria-label", "Click enter to expand and collapse filters");
        parentCategoryDiv.setAttribute("aria-expanded", "true");

        filterDropdownContainer.classList.add("filter-dropdown-closed");

        subcategoriesListContainerElement.innerHTML = "";

        data.sub_cat_array.forEach(subCategoryName => {

          var id_string = "category_"+subCategoryName.replace(/ /g,'')

          var container = document.createElement("div");
          container.classList.add("filter-category-item");
          // container.classList.add("hide");

          var checkbox = document.createElement('input');
          checkbox.type = "checkbox";
          checkbox.id = id_string;
          checkbox.name = "categories[]";
          checkbox.value = subCategoryName;
          var subcategoryLabel = document.createElement('label');
          subcategoryLabel.appendChild(document.createTextNode(subCategoryName));
          subcategoryLabel.setAttribute("for", id_string)
          container.appendChild(checkbox);
          container.appendChild(subcategoryLabel);

          subcategoriesListContainerElement.appendChild(container);
        });
      }
    });
  }
}

function _openCheckedSections() {
  var checkedBoxes = $('input:checkbox:checked');
  checkedBoxes.each(function() {
    if (($(this).closest('fieldset').siblings('div').hasClass('selected'))) {
      _openSection($(this).closest('fieldset').siblings('div'));
    }
  });
}

function _openSection(element) {

  document.querySelectorAll('.filter-category-item').forEach(function(item) {
    $(item).toggleClass('hide');
  });

  $(element).toggleClass('selected');
  $($(element).find('i')).toggleClass('fa fa-chevron-right fa fa-chevron-down');
}

function _collapseSections(evt) {
  if (evt.key === "Enter" || evt.type === 'click') {
    var sections = document.getElementsByClassName('parent-category-label-container');
    for (let section of sections) {
      _collapseSection($(section));
    }
  }
}

function _collapseSection(element) {
  var filters = element.nextUntil('depth0');
  filters.each(function() {
    $(this).children(0).addClass('hide');
  });
  $(element).attr('aria-expanded', 'false');
  $(element).removeClass('selected');
  $($(element).find('i')).removeClass('fa-chevron-down').addClass('fa-chevron-right');
}

function _handleHeaderClick(evt) {
  if (evt.key === "Enter" || evt.type === 'click') {
    let parentCategoryDiv = evt.currentTarget;
    let isExpanded = parentCategoryDiv.getAttribute('aria-expanded') === 'true';
    parentCategoryDiv.setAttribute('aria-expanded', (!isExpanded).toString());
    _openSection($(parentCategoryDiv));
  }
}

function _linkClickedHandler(evt) {
  var el = evt.target;
  if (el.nodeName == 'INPUT') {
    _checkState('depth', 0, el);
  }
}

function _checkState(prefix,depth,checkbox) {
  var item = $(checkbox).parent(); // parent li item
  var id = prefix+String(depth);
  while(!item.hasClass(id)) {
    depth++;
    id = prefix + String(depth);
  }

  id = 'li.' + prefix + String(depth+1);
  var lnks = $(id, item);
  var curr;
  for (var l=0; l < lnks.length; l++) {
    curr = lnks[l];
    if (checkbox.checked) {
      $(curr).removeClass('hide');
    }
    else {
      $(curr).addClass('hide');
      checkbox = $('input',$(curr));
      checkbox.prop('checked', false);
      _checkState(prefix,depth,checkbox);
    }
  }

}

document.addEventListener('DOMContentLoaded', function() {
  const searchContainer = document.getElementById('search-container');
  const searchHeader = searchContainer.querySelector('.search-container-header');
  const chevronIcon = searchHeader.querySelector('.chevron-icon');

  searchHeader.addEventListener('click', function() {
    searchContainer.classList.toggle('collapsed');
    chevronIcon.classList.toggle('open');
  });

  updateAppliedSearchOptionsCount();
});

document.querySelectorAll('input[type="checkbox"], input[type="text"], select').forEach(function(input) {
  input.addEventListener('change', updateAppliedSearchOptionsCount);
  input.addEventListener('input', updateAppliedSearchOptionsCount);
});

function updateAppliedSearchOptionsCount() {
  const keywordInput = document.querySelector('#keyword-search-box .search-input');
  const addressInput = document.getElementById('address');
  const languageSelect = document.getElementById('languages');
  const distanceSelect = document.getElementById('distance');

  const keyword = keywordInput ? keywordInput.value.trim().length > 0 : false;
  const address = addressInput && addressInput.value ? addressInput.value.trim().length > 0 : false;
  const geolocated = $('#button-geolocate').hasClass('geolocated');
  const selectedCategory = document.getElementById('main_category').value;
  const selectedLanguage = languageSelect ? languageSelect.value : null;
  const selectedDistance = distanceSelect ? distanceSelect.value : null;
  let selectedFilters = [];

  if (selectedCategory) {
    const categoryContainer = document.querySelector(`#subcategoriesList[data-category="${selectedCategory}"]`);
    if (categoryContainer) {
      selectedFilters = Array.from(categoryContainer.querySelectorAll('input[name="categories[]"]:checked')).map(checkbox => checkbox.value);
    }
  }

  const newCount = (keyword ? 1 : 0) +
                   (address ? 1 : 0) +
                   (geolocated ? 1 : 0) +
                   (selectedCategory ? 1 : 0) +
                   (selectedLanguage ? 1 : 0) +
                   (selectedDistance ? 1 : 0) +
                   selectedFilters.length;

  appliedSearchOptionsCount = newCount;

  const filterText = document.querySelector('.filter-text');
  const filterCount = document.querySelector('.filter-count');

  filterText.textContent = 'Filter';
  filterCount.textContent = appliedSearchOptionsCount === 0 ? '0' : appliedSearchOptionsCount;
}

document.addEventListener('DOMContentLoaded', function() {
  const languageSelect = document.getElementById('languages');
  const distanceSelect = document.getElementById('distance');
  const keywordSearchButton = document.getElementById('keyword-search-button');

  languageSelect.addEventListener('change', updateAppliedSearchOptionsCount);
  distanceSelect.addEventListener('change', updateAppliedSearchOptionsCount);
  keywordSearchButton.addEventListener('click', updateAppliedSearchOptionsCount);
});

export default {
  init:init
};
