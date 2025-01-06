// Manages the application initialization for all pages.
import alerts from './app/alerts';
import ahoy from "ahoy.js"

import 'core-js'
import 'regenerator-runtime/runtime'

import 'uppy/dist/uppy.min.css'

import { multipleFileUpload, singleFileUpload } from './fileUpload'

import tags from './app/recommended_tags';
import FeedbackForm from './app/FeedbackForm';
import filters from './app/search/filter/search-filters';
import map from './app/result/result-map';
import detailmap from './app/detail/detail-map';
import header from './app/search/header';
import cl from './app/detail/character-limited/character-limiter';
import utilityLinks from './app/detail/utility-links';
import './app/util/map/map_toggle';

document.addEventListener('turbolinks:load', () => {
  // All pages alerts init
  alerts.init();

  // Admin File Upload
  document.querySelectorAll(`input[data-uppy="true"]`).forEach((fileInput) => {
    if (fileInput.multiple) {
      multipleFileUpload(fileInput)
    } else {
      singleFileUpload(fileInput)
    }
  })
  // Home
  // Initialize the recommended tag searcher
  const keywordbox = document.getElementById("keyword");
  if (keywordbox) {
    tags.init();
  }
  //Home About
  // Manages initialization of scripts for the About page.
  // Initialize the feedback form
  const feedbackbox = document.getElementById("feedback-box");
  if (feedbackbox) {
    FeedbackForm.create('#feedback-box .feedback-form');
  }

  // Locations Index
  // Initialize the search filters
  const locationIndex = document.getElementsByClassName('locations index');
  if (locationIndex.length > 0) {
    filters.init();
    map.init();
    header.init();
  }


  // Locations Show
  const locationShow = document.getElementsByClassName('locations show');
  if (locationShow.length > 0) {
    detailmap.init();
    cl.init();
    header.init();
    utilityLinks.init();
    filters.init();
  }

  // Hamburger menu toggle functionality
  const hamburger = document.getElementById('hamburger');
  const navMenu = document.getElementById('nav-menu');
  const dropdownMenu = document.querySelector('.mobile-only.dropdown-menu');

  if (hamburger && navMenu && dropdownMenu) {
    hamburger.addEventListener('click', (e) => {
      e.stopPropagation();
      hamburger.classList.toggle('open');
      navMenu.classList.toggle('open');
      dropdownMenu.classList.toggle('open');
    });

    document.addEventListener('click', (e) => {
      if (!hamburger.contains(e.target) && !navMenu.contains(e.target) && !dropdownMenu.contains(e.target)) {
        hamburger.classList.remove('open');
        navMenu.classList.remove('open');
        dropdownMenu.classList.remove('open');
      }
    });    
  }

  // Profile dropdown in signed-in header
  const userBtn = document.getElementById('user-btn');
  const profileDropdown = document.getElementById('profile-dropdown');

  if (userBtn && profileDropdown) {
    userBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      userBtn.classList.toggle('open');
      profileDropdown.classList.toggle('open');
    });

    document.addEventListener('click', (e) => {
      if (!userBtn.contains(e.target) && !profileDropdown.contains(e.target)) {
        userBtn.classList.remove('open');
        profileDropdown.classList.remove('open');
      }
    });
  }
})
