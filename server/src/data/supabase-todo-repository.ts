import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import type { Todo, TodoRepository } from '../domain/todo.js';
import { asRows } from './postgrest-rows.js';

/**
 * 🔌 DATOS — implementación con Supabase (Postgres).
 * Usa el cliente oficial @supabase/supabase-js vía la Service Role Key.
 * Sustituye a InMemoryTodoRepository sin tocar rutas ni dominio.
 */
export class SupabaseTodoRepository implements TodoRepository {
  private readonly client: SupabaseClient;

  constructor(url: string, serviceRoleKey: string) {
    this.client = createClient(url, serviceRoleKey, {
      auth: { persistSession: false },
    });
  }

  async findAll(): Promise<Todo[]> {
    const { data, error } = await this.client
      .from('todos')
      .select('*')
      .order('id', { ascending: true });

    if (error) {
      throw new Error(`Supabase findAll: ${error.message}`);
    }
    return asRows<Todo>(data);
  }

  async findById(id: number): Promise<Todo | undefined> {
    const { data, error } = await this.client
      .from('todos')
      .select('*')
      .eq('id', id)
      .maybeSingle();

    if (error) {
      throw new Error(`Supabase findById: ${error.message}`);
    }
    return (data as Todo | null) ?? undefined;
  }

  async create(title: string): Promise<Todo> {
    const { data, error } = await this.client
      .from('todos')
      .insert({ title, completed: false })
      .select()
      .single();

    if (error) {
      throw new Error(`Supabase create: ${error.message}`);
    }
    return data as Todo;
  }
}
