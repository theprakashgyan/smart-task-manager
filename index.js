require("dotenv").config();
const express = require("express");
const cors = require("cors");
const { createClient } = require("@supabase/supabase-js");
const { z } = require("zod"); // Validation library
const { classifyTask } = require("./logic");

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Supabase Client Setup
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

// VALIDATION SCHEMAS [cite: 95]

const createTaskSchema = z.object({
  title: z.string().min(1, "Title is required"),
  description: z.string().optional(),
  assigned_to: z.string().nullable().optional(),
  due_date: z.string().nullable().optional(), // Expecting ISO string
  category: z.string().nullable().optional(), // Manual override
  priority: z.string().nullable().optional(), // Manual override
});

const updateTaskSchema = z.object({
  title: z.string().optional(),
  description: z.string().optional(),
  assigned_to: z.string().nullable().optional(),
  due_date: z.string().nullable().optional(),
  status: z.string().optional(),
  category: z.string().nullable().optional(),
  priority: z.string().nullable().optional(),
});

// ROUTES

// GET ALL TASKS (with Pagination & Filtering)
app.get("/api/tasks", async (req, res) => {
  try {
    const { page = 1, limit = 10, category, priority } = req.query;
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    let query = supabase
      .from("tasks")
      .select("*", { count: "exact" })
      .range(from, to)
      .order("created_at", { ascending: false });

    // Apply Filters
    if (category) query = query.eq("category", category);
    if (priority) query = query.eq("priority", priority);

    const { data, error, count } = await query;

    if (error) throw error;

    res.json({
      data,
      meta: {
        total_count: count,
        current_page: parseInt(page),
        per_page: parseInt(limit),
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 2. CREATE TASK (With Auto-Classification)
app.post("/api/tasks", async (req, res) => {
  try {
    // Validate Input
    const validatedData = createTaskSchema.parse(req.body);

    // Run "AI" Logic
    const analysis = classifyTask(
      validatedData.title,
      validatedData.description
    );

    // Prepare data for DB
    const newTask = {
      ...validatedData,
      category: validatedData.category || analysis.category, // Use override if present
      priority: validatedData.priority || analysis.priority, // Use override if present
      suggested_actions: analysis.suggested_actions,
      extracted_entities: analysis.extracted_entities,
      status: "pending",
    };

    // Insert into Supabase
    const { data, error } = await supabase
      .from("tasks")
      .insert([newTask])
      .select();

    if (error) throw error;

    res.status(201).json(data[0]);
  } catch (err) {
    // Proper error handling [cite: 96
    if (err instanceof z.ZodError) {
      return res
        .status(400)
        .json({ error: "Validation Error", details: err.errors });
    }
    console.error("Error creating task:", err);
    res.status(500).json({ error: err.message });
  }
});

// 3. DELETE TASK
app.delete("/api/tasks/:id", async (req, res) => {
  const { id } = req.params;
  const { error } = await supabase.from("tasks").delete().eq("id", id);

  if (error) return res.status(500).json({ error: error.message });
  res.json({ message: "Task deleted successfully" });
});

// 4. CLASSIFY TASK (Preview)
app.post("/api/classify", (req, res) => {
  const { title, description } = req.body;
  if (!title) return res.status(400).json({ error: "Title is required" });

  const analysis = classifyTask(title, description);
  res.json(analysis);
});

// 5. GET TASK DETAILS
app.get("/api/tasks/:id", async (req, res) => {
  const { id } = req.params;
  const { data, error } = await supabase
    .from("tasks")
    .select("*")
    .eq("id", id)
    .single();

  if (error) return res.status(500).json({ error: error.message });
  res.json(data);
});

// 6. UPDATE TASK
app.patch("/api/tasks/:id", async (req, res) => {
  const { id } = req.params;
  try {
    console.log("PATCH Received:", req.body); // DEBUG LOG
    const validatedData = updateTaskSchema.parse(req.body);
    const { data, error } = await supabase
      .from("tasks")
      .update(validatedData)
      .eq("id", id)
      .select();

    if (error) throw error;
    res.json(data[0]);
  } catch (err) {
    console.error("PATCH Error:", err); // DEBUG LOG
    if (err instanceof z.ZodError) {
      return res.status(400).json({ error: "Validation Error", details: err.errors });
    }
    res.status(500).json({ error: err.message });
  }
});

// Start Server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
