import { Hono } from 'hono'
import { serve } from '@hono/node-server'
import { serveStatic } from '@hono/node-server/serve-static'
import { readFileSync } from 'fs'
import { join, dirname } from 'path'
import { fileURLToPath } from 'url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const app = new Hono()

// Serve static assets
app.use('/static/*', serveStatic({ root: join(__dirname, 'public') }))

// Landing page
app.get('/', (c) => {
  const html = readFileSync(join(__dirname, 'public', 'index.html'), 'utf-8')
  return c.html(html)
})

// Health check
app.get('/health', (c) => c.json({ status: 'ok', version: '0.1.0' }))

const port = parseInt(process.env.PORT || '3000')
console.log(`🚢 Submarine landing page running on port ${port}`)

serve({ fetch: app.fetch, port })
