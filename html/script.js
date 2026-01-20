let markers = [];
let markersVisible = true;
let receiveLocationsAllowed = false;
let markerToDelete = null;
let markerToShare = null;
let markerToRename = null;
let receivedMarkerData = null;
let searchFilter = '';

const gpsContainer = document.getElementById('gpsContainer');
const closeBtn = document.getElementById('closeBtn');
const markBtn = document.getElementById('markBtn');
const locationLabel = document.getElementById('locationLabel');
const toggleMarkers = document.getElementById('toggleMarkers');
const toggleReceiveLocations = document.getElementById('toggleReceiveLocations');
const markersList = document.getElementById('markersList');
const markerCount = document.getElementById('markerCount');
const searchInput = document.getElementById('searchInput');
const confirmModal = document.getElementById('confirmModal');
const shareModal = document.getElementById('shareModal');
const receiveModal = document.getElementById('receiveModal');
const renameModal = document.getElementById('renameModal');
const confirmDelete = document.getElementById('confirmDelete');
const cancelDelete = document.getElementById('cancelDelete');
const confirmShare = document.getElementById('confirmShare');
const cancelShare = document.getElementById('cancelShare');
const confirmRename = document.getElementById('confirmRename');
const cancelRename = document.getElementById('cancelRename');
const renameInput = document.getElementById('renameInput');
const sharePlayerId = document.getElementById('sharePlayerId');
const acceptLocation = document.getElementById('acceptLocation');
const declineLocation = document.getElementById('declineLocation');
const senderName = document.getElementById('senderName');
const receiveLabel = document.getElementById('receiveLabel');
const receiveStreet = document.getElementById('receiveStreet');

closeBtn.addEventListener('click', closeUI);
markBtn.addEventListener('click', markLocation);
toggleMarkers.addEventListener('change', toggleMarkersVisibility);
toggleReceiveLocations.addEventListener('change', toggleReceiveLocations_handler);
confirmDelete.addEventListener('click', handleConfirmDelete);
cancelDelete.addEventListener('click', closeConfirmModal);
confirmShare.addEventListener('click', handleConfirmShare);
cancelShare.addEventListener('click', closeShareModal);
confirmRename.addEventListener('click', handleConfirmRename);
cancelRename.addEventListener('click', closeRenameModal);
acceptLocation.addEventListener('click', handleAcceptLocation);
declineLocation.addEventListener('click', handleDeclineLocation);

locationLabel.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        markLocation();
    }
});

searchInput.addEventListener('input', (e) => {
    searchFilter = e.target.value.toLowerCase();
    renderMarkers();
});

sharePlayerId.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        handleConfirmShare();
    }
});

renameInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        handleConfirmRename();
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (receiveModal.classList.contains('active')) {
            handleDeclineLocation();
        } else if (confirmModal.classList.contains('active')) {
            closeConfirmModal();
        } else if (shareModal.classList.contains('active')) {
            closeShareModal();
        } else if (renameModal.classList.contains('active')) {
            closeRenameModal();
        } else if (gpsContainer.classList.contains('active')) {
            closeUI();
        }
    }
});

window.addEventListener('message', (event) => {
    const data = event.data;
    
    switch(data.action) {
        case 'openUI':
            openUI(data.markers, data.markersVisible, data.receiveLocationsAllowed);
            break;
        case 'updateMarkers':
            updateMarkers(data.markers);
            break;
        case 'updateReceiveSetting':
            updateReceiveSetting(data.allowed);
            break;
        case 'receiveLocation':
            showReceiveModal(data.markerData, data.senderName);
            break;
    }
});

function openUI(markersData, visible, receiveAllowed) {
    markers = markersData || [];
    markersVisible = visible !== undefined ? visible : true;
    receiveLocationsAllowed = receiveAllowed !== undefined ? receiveAllowed : false;
    
    gpsContainer.classList.add('active');
    toggleMarkers.checked = markersVisible;
    toggleReceiveLocations.checked = receiveLocationsAllowed;
    
    searchFilter = '';
    searchInput.value = '';
    renderMarkers();
    locationLabel.value = '';
    locationLabel.focus();
}

function closeUI() {
    gpsContainer.classList.remove('active');
    fetch(`https://${resourceName}/closeUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

function markLocation() {
    const label = locationLabel.value.trim();
    
    if (!label) {
        return;
    }
    
    fetch(`https://${resourceName}/markLocation`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ label: label })
    });
    
    locationLabel.value = '';
}

function toggleMarkersVisibility() {
    markersVisible = toggleMarkers.checked;
    
    fetch(`https://${resourceName}/toggleMarkers`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ visible: markersVisible })
    });
}

function toggleReceiveLocations_handler() {
    receiveLocationsAllowed = toggleReceiveLocations.checked;
    
    fetch(`https://${resourceName}/toggleReceiveLocations`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ allowed: receiveLocationsAllowed })
    });
}

function updateMarkers(markersData) {
    markers = markersData || [];
    renderMarkers();
}

function updateReceiveSetting(allowed) {
    receiveLocationsAllowed = allowed;
    toggleReceiveLocations.checked = allowed;
}

function renderMarkers() {
    markerCount.textContent = markers.length;
    markersList.innerHTML = '';
    
    if (markers.length === 0) {
        markersList.innerHTML = `
            <div class="empty-state">
                <p>No saved locations yet.<br>Mark your current location to get started!</p>
            </div>
        `;
        return;
    }
    
    // Filter markers based on search query
    const filteredMarkers = markers.filter((marker, index) => {
        if (!searchFilter) return true;
        return marker.label.toLowerCase().includes(searchFilter);
    });
    
    if (filteredMarkers.length === 0) {
        markersList.innerHTML = `
            <div class="empty-state">
                <p>No locations match your search.<br>Try a different search term.</p>
            </div>
        `;
        return;
    }
    
    markers.forEach((marker, index) => {
        if (!searchFilter || marker.label.toLowerCase().includes(searchFilter)) {
            const markerItem = createMarkerElement(marker, index);
            markersList.appendChild(markerItem);
        }
    });
}

function createMarkerElement(marker, index) {
    const div = document.createElement('div');
    div.className = 'marker-item';
    
    div.innerHTML = `
        <div class="marker-header">
            <div class="marker-label">${escapeHtml(marker.label)}</div>
        </div>
        <div class="marker-actions">
            <button class="marker-btn waypoint" data-index="${index}">Waypoint</button>
            <button class="marker-btn delete" data-index="${index}">Remove</button>
            <button class="marker-btn rename" data-index="${index}">Rename</button>
            <button class="marker-btn share" data-index="${index}">Share</button>
        </div>
    `;
    
    const waypointBtn = div.querySelector('.waypoint');
    const deleteBtn = div.querySelector('.delete');
    const renameBtn = div.querySelector('.rename');
    const shareBtn = div.querySelector('.share');
    
    waypointBtn.addEventListener('click', () => setWaypoint(index));
    deleteBtn.addEventListener('click', () => openConfirmModal(index));
    renameBtn.addEventListener('click', () => openRenameModal(index));
    shareBtn.addEventListener('click', () => openShareModal(index));
    
    return div;
}

function setWaypoint(index) {
    fetch(`https://${resourceName}/setWaypoint`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ index: index + 1 })
    });
}

function openConfirmModal(index) {
    markerToDelete = index;
    confirmModal.classList.add('active');
}

function closeConfirmModal() {
    markerToDelete = null;
    confirmModal.classList.remove('active');
}

function handleConfirmDelete() {
    if (markerToDelete !== null) {
        fetch(`https://${resourceName}/removeMarker`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ index: markerToDelete + 1 })
        });
    }
    
    closeConfirmModal();
}

function openShareModal(index) {
    markerToShare = index;
    shareModal.classList.add('active');
    sharePlayerId.value = '';
    sharePlayerId.focus();
}

function closeShareModal() {
    markerToShare = null;
    shareModal.classList.remove('active');
    sharePlayerId.value = '';
}

function openRenameModal(index) {
    markerToRename = index;
    const marker = markers[index];
    if (marker) {
        renameInput.value = marker.label;
        renameModal.classList.add('active');
        renameInput.focus();
        renameInput.select();
    }
}

function closeRenameModal() {
    markerToRename = null;
    renameModal.classList.remove('active');
    renameInput.value = '';
}

function handleConfirmRename() {
    const newLabel = renameInput.value.trim();
    
    if (!newLabel) {
        return;
    }
    
    if (markerToRename !== null) {
        fetch(`https://${resourceName}/renameMarker`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ 
                index: markerToRename + 1,
                newLabel: newLabel
            })
        });
    }
    
    closeRenameModal();
}

function handleConfirmShare() {
    const playerId = parseInt(sharePlayerId.value);
    
    if (!playerId || playerId < 1) {
        return;
    }
    
    if (markerToShare !== null) {
        fetch(`https://${GetParentResourceName()}/shareMarker`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ 
                playerId: playerId,
                index: markerToShare + 1
            })
        });
    }
    
    closeShareModal();
}

function showReceiveModal(markerData, sender) {
    receivedMarkerData = markerData;
    senderName.textContent = sender;
    receiveLabel.textContent = markerData.label || 'Marked Location';
    receiveStreet.textContent = markerData.street || 'Unknown';
    receiveModal.classList.add('active');
}

function handleAcceptLocation() {
    if (receivedMarkerData) {
        fetch(`https://${resourceName}/acceptSharedLocation`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ 
                markerData: receivedMarkerData
            })
        });
    }
    closeReceiveModal();
}

function handleDeclineLocation() {
    fetch(`https://${resourceName}/declineSharedLocation`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
    closeReceiveModal();
}

function closeReceiveModal() {
    receiveModal.classList.remove('active');
    receivedMarkerData = null;
    fetch(`https://${resourceName}/closeReceiveModal`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

const resourceName = (typeof GetParentResourceName === 'function' && GetParentResourceName()) || 'Core_Gps_Advanced';

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
