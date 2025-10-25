// Main JavaScript file for MDT System
class MDTSystem {
    constructor() {
        this.currentPage = 'dashboard';
        this.userData = null;
        this.notifications = [];
        this.isLoading = false;
        this.charts = {};
        
        this.init();
    }

    async init() {
        try {
            // Ensure MDT is hidden on init
            this.hideMDT();
            
            this.showLoading();
            await this.loadUserData();
            await this.setupEventListeners();
            await this.loadDashboardData();
            this.hideLoading();
            // Don't automatically show MDT - wait for Lua client to trigger it
        } catch (error) {
            console.error('Failed to initialize MDT:', error);
            this.showError('Failed to initialize MDT system');
        }
    }

    showLoading() {
        const loadingScreen = document.getElementById('loading-screen');
        loadingScreen.classList.remove('hidden');
    }

    hideLoading() {
        const loadingScreen = document.getElementById('loading-screen');
        loadingScreen.classList.add('hidden');
    }

    showMDT() {
        console.log('MDT: showMDT() called');
        
        // Show loading screen first
        this.showLoading();
        
        // Hide loading and show MDT after 2 seconds
        setTimeout(() => {
            this.hideLoading();
            const mdtContainer = document.getElementById('mdt-container');
            mdtContainer.style.display = 'flex';
            mdtContainer.style.visibility = 'visible';
            mdtContainer.style.opacity = '1';
            console.log('MDT: Container shown');
        }, 2000);
    }

    hideMDT() {
        const mdtContainer = document.getElementById('mdt-container');
        mdtContainer.style.display = 'none';
        mdtContainer.style.visibility = 'hidden';
        mdtContainer.style.opacity = '0';
    }

    closeMDT() {
        console.log('MDT: Closing MDT via close button');
        this.hideMDT();
        // Send close message to Lua client
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    }

    async loadUserData() {
        return new Promise((resolve) => {
            // Simulate API call to get user data
            setTimeout(() => {
                this.userData = {
                    name: 'John Doe',
                    badge: 'Officer',
                    department: 'Police',
                    rank: 'Officer',
                    callsign: '1A-12'
                };
                this.updateUserInfo();
                resolve();
            }, 1000);
        });
    }

    updateUserInfo(playerData) {
        const userName = document.getElementById('user-name');
        const userBadge = document.getElementById('user-badge');
        
        if (userName && userBadge) {
            if (playerData) {
                userName.textContent = playerData.name || 'Unknown';
                userBadge.textContent = playerData.badge || 'Officer';
            } else if (this.userData) {
                userName.textContent = this.userData.name;
                userBadge.textContent = this.userData.badge;
            }
        }
    }

    setupEventListeners() {
        // Navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', (e) => {
                const page = e.currentTarget.dataset.page;
                console.log('MDT: Navigation clicked:', page);
                this.navigateToPage(page);
            });
        });

        // Search functionality
        const globalSearch = document.getElementById('global-search');
        if (globalSearch) {
            globalSearch.addEventListener('input', (e) => {
                this.handleGlobalSearch(e.target.value);
            });
        }

        // Action buttons
        document.getElementById('notifications-btn')?.addEventListener('click', () => {
            this.showNotifications();
        });

        document.getElementById('settings-btn')?.addEventListener('click', () => {
            this.showSettings();
        });

        document.getElementById('logout-btn')?.addEventListener('click', () => {
            this.logout();
        });

        document.getElementById('close-mdt-btn')?.addEventListener('click', () => {
            this.closeMDT();
        });

        // Page-specific buttons
        document.getElementById('new-incident-btn')?.addEventListener('click', () => {
            console.log('MDT: New Incident button clicked');
            this.showNewIncidentModal();
        });

        document.getElementById('add-citizen-btn')?.addEventListener('click', () => {
            this.showAddCitizenModal();
        });

        document.getElementById('add-vehicle-btn')?.addEventListener('click', () => {
            this.showAddVehicleModal();
        });

        document.getElementById('new-incident-report-btn')?.addEventListener('click', () => {
            this.showNewIncidentReportModal();
        });

        // Modal controls
        document.getElementById('modal-close')?.addEventListener('click', () => {
            this.closeModal();
        });

        document.getElementById('modal-overlay')?.addEventListener('click', (e) => {
            if (e.target.id === 'modal-overlay') {
                this.closeModal();
            }
        });

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            this.handleKeyboardShortcuts(e);
        });
    }

    navigateToPage(page) {
        // Update active nav item
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
        document.querySelector(`[data-page="${page}"]`)?.classList.add('active');

        // Update active page
        document.querySelectorAll('.page').forEach(pageEl => {
            pageEl.classList.remove('active');
        });
        document.getElementById(`${page}-page`)?.classList.add('active');

        this.currentPage = page;
        this.loadPageData(page);
    }

    async loadPageData(page) {
        switch (page) {
            case 'dashboard':
                await this.loadDashboardData();
                break;
            case 'citizens':
                await this.loadCitizensData();
                break;
            case 'vehicles':
                await this.loadVehiclesData();
                break;
            case 'incidents':
                await this.loadIncidentsData();
                break;
            default:
                console.log(`Loading data for page: ${page}`);
        }
    }

    // Fetch data from server
    async fetchData(dataType, query = '') {
        return new Promise((resolve, reject) => {
            fetch(`https://${GetParentResourceName()}/getData`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    type: dataType,
                    query: query
                })
            })
            .then(response => response.json())
            .then(data => resolve(data))
            .catch(error => {
                console.error('MDT: Error fetching data:', error);
                reject(error);
            });
        });
    }

    async loadDashboardData() {
        try {
            // Fetch real dashboard data from server
            const dashboardData = await this.fetchData('dashboard');
            this.updateDashboardStats(dashboardData);
            this.createDashboardCharts(dashboardData);
        } catch (error) {
            console.error('Failed to load dashboard data:', error);
        }
    }

    async fetchDashboardData() {
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve({
                    activeCalls: 3,
                    openCases: 12,
                    arrestsToday: 5,
                    activeWarrants: 8,
                    crimeStats: {
                        labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                        data: [12, 19, 3, 5, 2, 3]
                    },
                    responseTimes: {
                        labels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
                        data: [4.2, 3.8, 4.5, 3.9]
                    }
                });
            }, 500);
        });
    }

    updateDashboardStats(data) {
        document.getElementById('active-calls').textContent = data.activeCalls;
        document.getElementById('open-cases').textContent = data.openCases;
        document.getElementById('arrests-today').textContent = data.arrestsToday;
        document.getElementById('active-warrants').textContent = data.activeWarrants;
    }

    createDashboardCharts(data) {
        this.createCrimeChart(data.crimeStats);
        this.createResponseTimeChart(data.responseTimes);
    }

    createCrimeChart(data) {
        const ctx = document.getElementById('crime-chart');
        if (!ctx) return;

        if (this.charts.crime) {
            this.charts.crime.destroy();
        }

        this.charts.crime = new Chart(ctx, {
            type: 'line',
            data: {
                labels: data.labels,
                datasets: [{
                    label: 'Crime Reports',
                    data: data.data,
                    borderColor: '#1976D2',
                    backgroundColor: 'rgba(25, 118, 210, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        labels: {
                            color: '#FFFFFF'
                        }
                    }
                },
                scales: {
                    x: {
                        ticks: {
                            color: '#B0B0B0'
                        },
                        grid: {
                            color: '#333333'
                        }
                    },
                    y: {
                        ticks: {
                            color: '#B0B0B0'
                        },
                        grid: {
                            color: '#333333'
                        }
                    }
                }
            }
        });
    }

    createResponseTimeChart(data) {
        const ctx = document.getElementById('response-chart');
        if (!ctx) return;

        if (this.charts.response) {
            this.charts.response.destroy();
        }

        this.charts.response = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: data.labels,
                datasets: [{
                    label: 'Response Time (minutes)',
                    data: data.data,
                    backgroundColor: '#42A5F5',
                    borderColor: '#1976D2',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        labels: {
                            color: '#FFFFFF'
                        }
                    }
                },
                scales: {
                    x: {
                        ticks: {
                            color: '#B0B0B0'
                        },
                        grid: {
                            color: '#333333'
                        }
                    },
                    y: {
                        ticks: {
                            color: '#B0B0B0'
                        },
                        grid: {
                            color: '#333333'
                        }
                    }
                }
            }
        });
    }

    async loadCitizensData() {
        try {
            console.log('MDT: Loading citizens data...');
            const citizens = await this.fetchData('citizens');
            console.log('MDT: Received citizens data:', citizens);
            this.populateCitizensTable(citizens);
        } catch (error) {
            console.error('Failed to load citizens data:', error);
        }
    }

    async fetchCitizensData() {
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve([
                    { id: 1, name: 'John Smith', dob: '1990-05-15', license: 'D1234567', status: 'Active' },
                    { id: 2, name: 'Jane Doe', dob: '1985-12-03', license: 'D2345678', status: 'Active' },
                    { id: 3, name: 'Bob Johnson', dob: '1992-08-22', license: 'D3456789', status: 'Suspended' }
                ]);
            }, 500);
        });
    }

    populateCitizensTable(citizens) {
        console.log('MDT: Populating citizens table with:', citizens);
        const tbody = document.getElementById('citizens-tbody');
        if (!tbody) {
            console.error('MDT: citizens-tbody element not found');
            return;
        }

        if (!citizens || citizens.length === 0) {
            console.log('MDT: No citizens data to display');
            tbody.innerHTML = '<tr><td colspan="6" class="text-center">No citizens found</td></tr>';
            return;
        }

        tbody.innerHTML = citizens.map(citizen => `
            <tr>
                <td>${citizen.citizenid || 'N/A'}</td>
                <td>${citizen.firstname || ''} ${citizen.lastname || ''}</td>
                <td>${citizen.birthdate || 'N/A'}</td>
                <td>${citizen.license || 'N/A'}</td>
                <td><span class="status-badge ${(citizen.status || 'active').toLowerCase()}">${citizen.status || 'active'}</span></td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="mdtSystem.viewCitizen('${citizen.citizenid || ''}')">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-sm btn-secondary" onclick="mdtSystem.editCitizen('${citizen.citizenid || ''}')">
                        <i class="fas fa-edit"></i>
                    </button>
                </td>
            </tr>
        `).join('');
    }

    async loadVehiclesData() {
        try {
            const vehicles = await this.fetchData('vehicles');
            this.populateVehiclesTable(vehicles);
        } catch (error) {
            console.error('Failed to load vehicles data:', error);
        }
    }

    async fetchVehiclesData() {
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve([
                    { plate: 'ABC123', model: 'Sedan', owner: 'John Smith', status: 'Valid', insurance: 'Active' },
                    { plate: 'XYZ789', model: 'SUV', owner: 'Jane Doe', status: 'Valid', insurance: 'Active' },
                    { plate: 'DEF456', model: 'Truck', owner: 'Bob Johnson', status: 'Expired', insurance: 'Expired' }
                ]);
            }, 500);
        });
    }

    populateVehiclesTable(vehicles) {
        const tbody = document.getElementById('vehicles-tbody');
        if (!tbody) return;

        tbody.innerHTML = vehicles.map(vehicle => `
            <tr>
                <td>${vehicle.plate}</td>
                <td>${vehicle.model}</td>
                <td>${vehicle.owner}</td>
                <td><span class="status-badge ${vehicle.status.toLowerCase()}">${vehicle.status}</span></td>
                <td><span class="status-badge ${vehicle.insurance.toLowerCase()}">${vehicle.insurance}</span></td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="mdtSystem.viewVehicle('${vehicle.plate}')">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-sm btn-secondary" onclick="mdtSystem.editVehicle('${vehicle.plate}')">
                        <i class="fas fa-edit"></i>
                    </button>
                </td>
            </tr>
        `).join('');
    }

    async loadIncidentsData() {
        try {
            const incidents = await this.fetchData('incidents');
            this.populateIncidentsTable(incidents);
        } catch (error) {
            console.error('Failed to load incidents data:', error);
        }
    }

    async fetchIncidentsData() {
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve([
                    { id: 1, type: 'Traffic Violation', location: 'Main St', officer: 'John Doe', date: '2024-01-15', status: 'Open' },
                    { id: 2, type: 'Theft', location: 'Downtown', officer: 'Jane Smith', date: '2024-01-14', status: 'Closed' },
                    { id: 3, type: 'Assault', location: 'Park Ave', officer: 'Bob Wilson', date: '2024-01-13', status: 'Pending' }
                ]);
            }, 500);
        });
    }

    populateIncidentsTable(incidents) {
        const tbody = document.getElementById('incidents-tbody');
        if (!tbody) return;

        tbody.innerHTML = incidents.map(incident => `
            <tr>
                <td>${incident.id}</td>
                <td>${incident.type}</td>
                <td>${incident.location}</td>
                <td>${incident.officer}</td>
                <td>${incident.date}</td>
                <td><span class="status-badge ${incident.status.toLowerCase()}">${incident.status}</span></td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="mdtSystem.viewIncident(${incident.id})">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-sm btn-secondary" onclick="mdtSystem.editIncident(${incident.id})">
                        <i class="fas fa-edit"></i>
                    </button>
                </td>
            </tr>
        `).join('');
    }

    handleGlobalSearch(query) {
        if (query.length < 2) return;
        
        console.log('Global search:', query);
        // Implement global search functionality
    }

    handleKeyboardShortcuts(e) {
        if (e.key === 'Escape') {
            e.preventDefault();
            this.closeMDT();
            return;
        }
        
        if (e.ctrlKey || e.metaKey) {
            switch (e.key) {
                case 'k':
                    e.preventDefault();
                    document.getElementById('global-search')?.focus();
                    break;
                case 'n':
                    e.preventDefault();
                    this.showNewIncidentModal();
                    break;
            }
        }
    }

    showModal(title, content) {
        const modal = document.getElementById('modal-overlay');
        const modalTitle = document.getElementById('modal-title');
        const modalContent = document.getElementById('modal-content');
        
        if (modalTitle) modalTitle.textContent = title;
        if (modalContent) modalContent.innerHTML = content;
        
        modal?.classList.remove('hidden');
    }

    closeModal() {
        const modal = document.getElementById('modal-overlay');
        modal?.classList.add('hidden');
    }

    showNewIncidentModal() {
        const content = `
            <form id="new-incident-form">
                <div class="form-group">
                    <label for="incident-type">Incident Type</label>
                    <select id="incident-type" required>
                        <option value="">Select Type</option>
                        <option value="traffic">Traffic Violation</option>
                        <option value="theft">Theft</option>
                        <option value="assault">Assault</option>
                        <option value="other">Other</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="incident-location">Location</label>
                    <input type="text" id="incident-location" required>
                </div>
                <div class="form-group">
                    <label for="incident-description">Description</label>
                    <textarea id="incident-description" rows="4" required></textarea>
                </div>
                <div class="form-actions">
                    <button type="button" class="btn btn-secondary" onclick="mdtSystem.closeModal()">Cancel</button>
                    <button type="submit" class="btn btn-primary">Create Incident</button>
                </div>
            </form>
        `;
        
        this.showModal('New Incident Report', content);
        
        // Add form submission handler
        document.getElementById('new-incident-form')?.addEventListener('submit', (e) => {
            e.preventDefault();
            this.createIncident();
        });
    }

    showAddCitizenModal() {
        const content = `
            <form id="add-citizen-form">
                <div class="form-group">
                    <label for="citizen-name">Full Name</label>
                    <input type="text" id="citizen-name" required>
                </div>
                <div class="form-group">
                    <label for="citizen-dob">Date of Birth</label>
                    <input type="date" id="citizen-dob" required>
                </div>
                <div class="form-group">
                    <label for="citizen-license">License Number</label>
                    <input type="text" id="citizen-license" required>
                </div>
                <div class="form-actions">
                    <button type="button" class="btn btn-secondary" onclick="mdtSystem.closeModal()">Cancel</button>
                    <button type="submit" class="btn btn-primary">Add Citizen</button>
                </div>
            </form>
        `;
        
        this.showModal('Add New Citizen', content);
    }

    showAddVehicleModal() {
        const content = `
            <form id="add-vehicle-form">
                <div class="form-group">
                    <label for="vehicle-plate">License Plate</label>
                    <input type="text" id="vehicle-plate" required>
                </div>
                <div class="form-group">
                    <label for="vehicle-model">Vehicle Model</label>
                    <input type="text" id="vehicle-model" required>
                </div>
                <div class="form-group">
                    <label for="vehicle-owner">Owner</label>
                    <input type="text" id="vehicle-owner" required>
                </div>
                <div class="form-actions">
                    <button type="button" class="btn btn-secondary" onclick="mdtSystem.closeModal()">Cancel</button>
                    <button type="submit" class="btn btn-primary">Add Vehicle</button>
                </div>
            </form>
        `;
        
        this.showModal('Add New Vehicle', content);
    }

    showNewIncidentReportModal() {
        const content = `
            <form id="new-incident-report-form">
                <div class="form-group">
                    <label for="report-type">Report Type</label>
                    <select id="report-type" required>
                        <option value="">Select Type</option>
                        <option value="arrest">Arrest Report</option>
                        <option value="incident">Incident Report</option>
                        <option value="traffic">Traffic Report</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="report-subject">Subject</label>
                    <input type="text" id="report-subject" required>
                </div>
                <div class="form-group">
                    <label for="report-details">Report Details</label>
                    <textarea id="report-details" rows="6" required></textarea>
                </div>
                <div class="form-actions">
                    <button type="button" class="btn btn-secondary" onclick="mdtSystem.closeModal()">Cancel</button>
                    <button type="submit" class="btn btn-primary">Create Report</button>
                </div>
            </form>
        `;
        
        this.showModal('New Incident Report', content);
    }

    async createIncident() {
        // Implement incident creation
        this.closeModal();
        this.showNotification('Incident created successfully', 'success');
    }

    showNotifications() {
        // Implement notifications panel
        console.log('Show notifications');
    }

    showSettings() {
        // Implement settings panel
        console.log('Show settings');
    }

    logout() {
        if (confirm('Are you sure you want to logout?')) {
            // Implement logout
            console.log('Logging out...');
        }
    }

    showNotification(message, type = 'info') {
        const container = document.getElementById('notifications-container');
        if (!container) return;

        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.innerHTML = `
            <div class="notification-content">
                <i class="fas fa-${this.getNotificationIcon(type)}"></i>
                <span>${message}</span>
            </div>
            <button class="notification-close" onclick="this.parentElement.remove()">
                <i class="fas fa-times"></i>
            </button>
        `;

        container.appendChild(notification);

        // Auto remove after 5 seconds
        setTimeout(() => {
            if (notification.parentElement) {
                notification.remove();
            }
        }, 5000);
    }

    getNotificationIcon(type) {
        const icons = {
            success: 'check-circle',
            error: 'times-circle',
            warning: 'exclamation-triangle',
            info: 'info-circle'
        };
        return icons[type] || 'info-circle';
    }

    showError(message) {
        this.showNotification(message, 'error');
    }

    // Placeholder methods for future implementation
    viewCitizen(id) { console.log('View citizen:', id); }
    editCitizen(id) { console.log('Edit citizen:', id); }
    viewVehicle(plate) { console.log('View vehicle:', plate); }
    editVehicle(plate) { console.log('Edit vehicle:', plate); }
    viewIncident(id) { console.log('View incident:', id); }
    editIncident(id) { console.log('Edit incident:', id); }
}

// Initialize MDT System when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    console.log('MDT: DOM loaded, initializing...');
    window.mdtSystem = new MDTSystem();
    
    // Add a test to see if MDT is being shown automatically
    setTimeout(() => {
        const mdtContainer = document.getElementById('mdt-container');
        if (mdtContainer.style.display !== 'none' || mdtContainer.style.visibility !== 'hidden' || mdtContainer.style.opacity !== '0') {
            console.log('MDT: WARNING - MDT is visible without being opened!');
            console.log('MDT: Current styles - display:', mdtContainer.style.display, 'visibility:', mdtContainer.style.visibility, 'opacity:', mdtContainer.style.opacity);
            mdtContainer.style.display = 'none';
            mdtContainer.style.visibility = 'hidden';
            mdtContainer.style.opacity = '0';
        } else {
            console.log('MDT: MDT is properly hidden');
        }
    }, 2000);
});

// Listen for messages from Lua client
window.addEventListener('message', (event) => {
    const data = event.data;
    console.log('MDT: Received message:', data);
    
    if (data.type === 'open') {
        console.log('MDT: Opening MDT via message');
        window.mdtSystem.showMDT();
        if (data.data && data.data.player) {
            window.mdtSystem.updateUserInfo(data.data.player);
        }
    } else if (data.type === 'close') {
        console.log('MDT: Closing MDT via message');
        window.mdtSystem.hideMDT();
    } else if (data.type === 'playerData') {
        window.mdtSystem.updateUserInfo(data.data);
    } else if (data.type === 'updateData') {
        // Handle data updates
        console.log('Updating data:', data.data);
    } else if (data.type === 'notification') {
        window.mdtSystem.showNotification(data.data.message, data.data.type);
    }
});
