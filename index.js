const API_URL = "https://camryn-cloud-resume.azurewebsites.net/api/http_trigger?";


async function updateCount(){
    const res = await fetch(API_URL)
    let count = await res.json();
    const visitorCounter = document.querySelector('.count')
    visitorCounter.innerHTML = count
}

document.addEventListener("DOMContentLoaded", event =>{
    updateCount()
})