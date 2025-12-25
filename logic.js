function classifyTask(title, description = "") {
  const fullText = title + " " + description;
  const lowerText = fullText.toLowerCase();

  // Determine Category
  let category = "general"; // Default
  if (lowerText.match(/(meeting|schedule|call|appointment|deadline)/)) {
    category = "scheduling";
  } else if (lowerText.match(/(payment|invoice|bill|budget|cost|expense)/)) {
    category = "finance";
  } else if (lowerText.match(/(bug|fix|error|install|repair|maintain)/)) {
    category = "technical";
  } else if (lowerText.match(/(safety|hazard|inspection|compliance|ppe)/)) {
    category = "safety";
  }

  // Determine Priority
  let priority = "low"; // Default
  if (lowerText.match(/(urgent|asap|immediately|today|critical|emergency)/)) {
    priority = "high";
  } else if (lowerText.match(/(soon|this week|important)/)) {
    priority = "medium";
  }

  // extract Entities
  const extracted_entities = {};

  // 1. Dates (Basic Regex for common terms)
  const dateMatch = lowerText.match(/(today|tomorrow|next (monday|tuesday|wednesday|thursday|friday|week)|(\d{1,2}(st|nd|rd|th)? (jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)))/i);
  if (dateMatch) extracted_entities.date = dateMatch[0];

  // 2. People (after with, by, assign to)
  const personMatch = fullText.match(/(?:with|by|assign to)\s+([A-Z][a-z]+)/);
  if (personMatch) extracted_entities.person = personMatch[1];

  // 3. Location (at, in) - Very basic heuristic
  const locationMatch = fullText.match(/(?:at|in)\s+([A-Z][a-z]+(\s[A-Z][a-z]+)*)/);
  // Filter out common prepositions or non-locations if needed, but keeping it simple
  if (locationMatch && !['the', 'a', 'my'].includes(locationMatch[1].toLowerCase())) {
    extracted_entities.location = locationMatch[1];
  }

  // Suggested Actions
  const actionsMap = {
    scheduling: ["Block calendar", "Send invite", "Prepare agenda"],
    finance: ["Check budget", "Get approval", "Generate invoice"],
    technical: ["Diagnose issue", "Check resources", "Document fix"],
    safety: ["Conduct inspection", "File report", "Notify supervisor"],
    general: ["Review task details"],
  };

  return {
    category,
    priority,
    suggested_actions: actionsMap[category],
    extracted_entities
  };
}

module.exports = { classifyTask };
