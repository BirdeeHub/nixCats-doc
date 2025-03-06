class AutocompleteComponent extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
    this.shadowRoot.innerHTML = `
      <style>
        #overlay {
          all: unset;
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          display: none;
          background-color: rgba(0, 0, 0, 0.5);
          justify-content: center;
          align-items: center;
          z-index: 1000;
          color-scheme: inherit;
        }
        #text-box {
          padding: 1rem;
          border-radius: 8px;
          box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
          display: flex;
          flex-direction: column;
          align-items: stretch;
        }
        input {
          padding: 0.5rem;
          font-size: 1rem;
        }
        input::placeholder {
          color: gray;
        }
        #suggestions {
          list-style-type: none;
          padding: 0;
          margin-bottom: 10px;
          border: 1px solid;
          border-radius: 4px;
          max-height: 150px;
          overflow-y: auto;
        }
        #suggestions li {
          padding: 0.5rem;
          cursor: pointer;
        }
        #suggestions li:hover, #suggestions .selected {
          background-color: #a0a0a0;
          color: black;
        }
        .themewcli {
          background-color: black;
          color: white;
          border-color: white;
        }
        @media (prefers-color-scheme: light) {
          .themewcli.adaptive {
            background-color: whitesmoke;
            color: black;
            border-color: black;
          }
        }
      </style>
      <div id="overlay">
        <div id="text-box" class="themewcli adaptive">
          <ul id="suggestions"></ul>
          <input type="text" placeholder="help nixCats.*"/>
        </div>
      </div>
    `;
    this.overlay = this.shadowRoot.querySelector('#overlay');
    this.modal = this.shadowRoot.querySelector('#text-box');
    this.input = this.shadowRoot.querySelector('input');
    this.suggestionsList = this.shadowRoot.querySelector('#suggestions');

    this.commandStrings = [ "h", "help" ];

    this.suggestiondata = [];
    this.tagdata = null;
    fetch('./suggestions.json')
      .then(response => response.json())
      .then(data => {
        this.suggestiondata = Object.keys(data);
        this.tagdata = data;
      })
      .catch(error => console.error('Error loading the JSON:', error));

    this.selectedIndex = -1;
  }

  connectedCallback() {
    this.handleInput()
    document.addEventListener('keydown', this.keyHandler.bind(this));
    this.input.addEventListener('input', this.handleInput.bind(this));
    this.overlay.addEventListener('click', (_) => {
      this.overlay.style.display = 'none';
    });
    this.modal.addEventListener('click', (event) => {
      event.stopPropagation();
    });
  }

  disconnectedCallback() {
    document.removeEventListener('keydown', this.keyHandler.bind(this));
    this.input.removeEventListener('input', this.handleInput.bind(this));
  }

  keyHandler(event) {
    if (event.key === ':') {
      if (!this.overlay.style.display || this.overlay.style.display === 'none') {
        event.preventDefault();
        this.overlay.style.display = 'flex';
        setTimeout(() => this.input.focus(), 0);
      }
    } else if (event.key === 'Escape') {
      this.overlay.style.display = 'none';
    } else if (event.key === 'Enter') {
      const focusedElement = this.shadowRoot.activeElement;
      if (focusedElement === this.input) {
        event.preventDefault();
        this.handleSubmit();
      } else if (focusedElement.tagName === 'LI') {
        event.preventDefault();
        this.selectSuggestion(focusedElement)
      }
    } else if (event.key === 'Tab' || event.key === 'ArrowDown' || event.key === 'ArrowUp') {
      this.handleMoveFocus(event);
    }
  }

  selectSuggestion(element) {
      this.selectedIndex = -1;
      this.input.value = element.textContent;
      this.suggestionsList.querySelectorAll('li').forEach(item => item.classList.remove('selected'));
      this.input.focus();
      this.handleInput();
      this.suggestionsList.innerHTML = '';
  }

  handleInput() {
    const suggestions = this.filterSuggestions(this.input.value);
    this.displaySuggestions(suggestions);
    if (!suggestions.length && this.input.value.length) {
      this.input.style.borderColor = 'red';
    } else {
      if (this.input.value.length) {
        let words = this.input.value.trim().split(/\s+/);
        if (!this.commandStrings.includes(words[0])) {
          this.input.style.borderColor = 'red';
        } else if (!this.suggestiondata.includes(words[1])) {
          this.input.style.borderColor = 'red';
        } else {
          this.input.style.borderColor = '';
        }
      } else {
        this.input.style.borderColor = '';
      }
    }
  }

  handleSubmit() {
    const query = this.input.value.trim().replace(/^[^\s]+\s+/, '');
    if (this.tagdata && this.tagdata[query]) {
      window.location.href = this.tagdata[query]; // Navigate to the relative path
      this.input.value = '';
      this.overlay.style.display = 'none';
    } else {
      console.warn('No matching entry found in tagdata for:', query);
    }
  }

  filterSuggestions(query_in) {
    const query = query_in.trimStart().toLowerCase();
    const filtered_cmds = this.commandStrings.filter(item => item.toLowerCase().startsWith(query));
    if (!query.length || !/\s/.test(query) && filtered_cmds.length) {
      return filtered_cmds;
    } else {
      const match_commands = (q, cl) => cl.filter(item => new RegExp(`^${item}\\s+`).test(q)).length;
      var remaining = query.replace(/^[^\s]+\s+/, '').trimEnd();
      if (match_commands(query, ["h", "help"])) {
        if (remaining.length) {
          return this.suggestiondata.filter(item => 
            item.toLowerCase().includes(remaining)
          ).map(item => query.replace(/^([^\s]+\s+).*/, (_, prefix) => prefix + item));
        } else {
          return this.suggestiondata.map(item => query.replace(/^([^\s]+\s+).*/, (_, prefix) => prefix + item));
        }
      }
    }
    return [];
  }

  displaySuggestions(filtered) {
    this.suggestionsList.innerHTML = '';
    if (filtered && filtered.length > 0) {
      filtered.forEach((suggestion, index) => {
        const li = document.createElement('li');
        li.textContent = suggestion;
        li.dataset.index = index;
        li.tabIndex = 0;
        li.addEventListener('click', () => this.selectSuggestion(li));
        this.suggestionsList.appendChild(li);
      });
    }
  }

  handleMoveFocus(event) {
    event.preventDefault(); // Prevent the default tab behavior
    const items = this.suggestionsList.querySelectorAll('li');
    if (event.shiftKey && event.key === 'Tab' || event.key === 'ArrowUp') {
      if (this.selectedIndex >= 0) {
        this.selectedIndex--;
      } else {
        this.selectedIndex = items.length - 1;
      }
    } else {
      if (this.selectedIndex < items.length - 1) {
        this.selectedIndex++;
      } else {
        this.selectedIndex = -1;
      }
    }

    // Update the selected item visually
    items.forEach(item => item.classList.remove('selected'));
    if (this.selectedIndex >= 0) {
      items[this.selectedIndex].classList.add('selected');
      items[this.selectedIndex].focus();
    } else {
      this.input.focus();
    }
  }

}

customElements.define('vim-help', AutocompleteComponent);
