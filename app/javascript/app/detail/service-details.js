function init() {

  let serviceRows = document.querySelectorAll('.service-row');
  if (serviceRows) {
    serviceRows.forEach( row => {
        row.addEventListener("click", toggleServiceCard);
    });
  }

  let serviceItems = document.querySelectorAll('.service-item');
  if (serviceItems) {
    serviceItems.forEach( item => {
        item.addEventListener("click", openServiceCard);
    });
  }
}


// Open service details card
function openServiceCard(e){
  const serviceRowId = e.target.id;
  const i = serviceRowId.split("-").pop();

  let chevron = document.getElementById(`service-chevron-${i}`);
  chevron.classList.add("fa-chevron-up");
  chevron.classList.remove("fa-chevron-down");

  let titleElement = document.getElementById(`service-title-${i}`);
  titleElement.classList.add("open");

  let alternateTitleElement = document.getElementById(`service-alt-${i}`);
  if (alternateTitleElement) {
      alternateTitleElement.classList.add("open");
  }

  let serviceCardElement = document.getElementById(`service-card-${i}`);
  serviceCardElement.classList.remove("closed");

  chevron.scrollIntoView({ alignToTop: true, behavior: "smooth"});
}


// Toggle service details card open or closed
function toggleServiceCard(e){
  const serviceRowId = e.target.id;
  const i = serviceRowId.split("-").pop();

  let chevron = document.getElementById(`service-chevron-${i}`);
  chevron.classList.toggle("fa-chevron-down");
  chevron.classList.toggle("fa-chevron-up");

  let titleElement = document.getElementById(`service-title-${i}`);
  titleElement.classList.toggle("open");

  let alternateTitleElement = document.getElementById(`service-alt-${i}`);
  if (alternateTitleElement) {
    alternateTitleElement.classList.toggle("open");
  }

  let serviceCardElement = document.getElementById(`service-card-${i}`);
  serviceCardElement.classList.toggle("closed");
}