---
title: "Suggest a Resource"
layout: "page"
url: "/suggest/"
summary: "Suggest a new resource for our library"
---

<style>
  .suggest-form {
    max-width: 800px;
    margin: 0 auto;
  }
  
  .form-group {
    margin-bottom: 1.5rem;
  }
  
  label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 500;
  }
  
  input[type="text"],
  input[type="email"],
  input[type="url"],
  textarea,
  select {
    width: 100%;
    padding: 0.5rem;
    border: 1px solid var(--border);
    border-radius: 4px;
    background: var(--entry);
    color: var(--primary);
  }
  
  .tag-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 1rem;
    margin-bottom: 1rem;
  }
  
  .tag-option {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }
  
  .checkbox-group {
    margin-top: 1rem;
  }
  
  button[type="submit"] {
    background: var(--primary);
    color: var(--theme);
    padding: 0.75rem 1.5rem;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-weight: 500;
  }
  
  button[type="submit"]:hover {
    opacity: 0.9;
  }

  .success-message {
    display: none;
    text-align: center;
    padding: 2rem;
    background: var(--entry);
    border-radius: 4px;
  }
</style>

<!-- Formbricks Script -->
<script async src="https://cdn.formbricks.com/sdk.js"></script>

<div class="suggest-form">
  <form id="resourceForm">
    <div class="form-group">
      <label for="name">Your Name *</label>
      <input type="text" id="name" name="name" required>
    </div>

    <div class="form-group">
      <label for="email">Your Email *</label>
      <input type="email" id="email" name="email" required>
    </div>

    <div class="form-group">
      <label for="resource-title">Title of Resource *</label>
      <input type="text" id="resource-title" name="resource-title" required>
    </div>

    <div class="form-group">
      <label for="resource-url">Resource URL *</label>
      <input type="url" id="resource-url" name="resource-url" required>
    </div>

    <div class="form-group">
      <label>Suggested Tags</label>
      <div class="tag-grid">
        <!-- Replace these with your actual tags -->
        <div class="tag-option">
          <input type="checkbox" id="tag1" name="tags[]" value="Education">
          <label for="tag1">Education</label>
        </div>
        <div class="tag-option">
          <input type="checkbox" id="tag2" name="tags[]" value="Technology">
          <label for="tag2">Technology</label>
        </div>
        <div class="tag-option">
          <input type="checkbox" id="tag3" name="tags[]" value="Research">
          <label for="tag3">Research</label>
        </div>
        <!-- Add more tags as needed -->
      </div>
    </div>

    <div class="form-group">
      <label for="organization">Organization</label>
      <input type="text" id="organization" name="organization">
    </div>

    <div class="form-group">
      <label for="notes">Additional Notes</label>
      <textarea id="notes" name="notes" rows="4"></textarea>
    </div>

    <div class="checkbox-group">
      <input type="checkbox" id="is-correction" name="is-correction">
      <label for="is-correction">This is a correction to a previous submission</label>
    </div>

    <button type="submit">Submit Resource</button>
  </form>

  <div id="successMessage" class="success-message">
    <h3>Thank you for your submission!</h3>
    <p>Your resource suggestion has been received and will be reviewed soon.</p>
  </div>
</div>

<script>
  // Initialize Formbricks
  window.formbricks = {
    config: {
      environmentId: "cm5fpdaqm000ajj035xuyaqfk",
      apiHost: "https://app.formbricks.com",
      debug: false // Set to true for development
    }
  };

  // Handle form submission
  document.getElementById('resourceForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    // Get selected tags
    const selectedTags = Array.from(document.querySelectorAll('input[name="tags[]"]:checked'))
      .map(checkbox => checkbox.value);

    // Prepare form data
    const formData = {
      name: document.getElementById('name').value,
      email: document.getElementById('email').value,
      resourceTitle: document.getElementById('resource-title').value,
      resourceUrl: document.getElementById('resource-url').value,
      tags: selectedTags,
      organization: document.getElementById('organization').value,
      notes: document.getElementById('notes').value,
      isCorrection: document.getElementById('is-correction').checked
    };

    try {
      // Submit to Formbricks
      await window.formbricks.track("resource_suggestion", formData);
      
      // Show success message
      document.getElementById('resourceForm').style.display = 'none';
      document.getElementById('successMessage').style.display = 'block';
    } catch (error) {
      console.error('Error submitting form:', error);
      alert('There was an error submitting your form. Please try again.');
    }
  });
</script>