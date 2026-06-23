import { NextRequest, NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { getSessionUser, canAccessTenant } from '@/lib/auth'
import { writeFile, mkdir } from 'fs/promises'
import path from 'path'

const UPLOAD_DIR = 'uploads'
const MAX_FILE_SIZE = 25 * 1024 * 1024 // 25MB

export async function POST(req: NextRequest) {
  try {
    const user = await getSessionUser()
    if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

    const formData = await req.formData()
    const file = formData.get('file') as File | null
    const title = formData.get('title') as string | null
    const description = formData.get('description') as string | null
    const tags = formData.get('tags') as string | null
    const controlId = formData.get('controlId') as string | null
    const tenantId = formData.get('tenantId') as string | null

    if (!file) return NextResponse.json({ error: 'No file provided' }, { status: 400 })
    if (!title) return NextResponse.json({ error: 'Title is required' }, { status: 400 })

    if (file.size > MAX_FILE_SIZE) {
      return NextResponse.json({ error: 'File too large. Maximum 25MB allowed.' }, { status: 400 })
    }

    const targetTenantId = user.role === 'super_admin' ? (tenantId || user.tenantId) : user.tenantId
    if (!targetTenantId) return NextResponse.json({ error: 'Tenant required' }, { status: 400 })
    if (!canAccessTenant(user, targetTenantId)) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })

    // Validate file type
    const allowedMimes = [
      'application/pdf',
      'image/png', 'image/jpeg', 'image/gif', 'image/webp', 'image/svg+xml',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/csv',
      'application/vnd.ms-powerpoint',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'text/plain',
      'application/zip', 'application/x-zip-compressed',
      'application/json',
      'application/xml', 'text/xml',
    ]
    if (file.type && !allowedMimes.includes(file.type) && !file.type.startsWith('image/')) {
      return NextResponse.json({ error: `File type "${file.type}" is not allowed.` }, { status: 400 })
    }

    // Read file bytes
    const bytes = await file.arrayBuffer()
    const buffer = Buffer.from(bytes)

    // Sanitize filename and generate unique path
    const sanitized = file.name.replace(/[^a-zA-Z0-9._-]/g, '_').replace(/_+/g, '_')
    const ext = path.extname(sanitized) || ''
    const baseName = path.basename(sanitized, ext)
    const timestamp = Date.now()
    const uniqueName = `${baseName}_${timestamp}${ext}`
    const relativeDir = `${UPLOAD_DIR}/${targetTenantId}`
    const relativePath = `${relativeDir}/${uniqueName}`

    // Ensure directory exists
    const fullDir = path.join(process.cwd(), 'public', relativeDir)
    await mkdir(fullDir, { recursive: true })

    // Write file to disk
    const fullPath = path.join(process.cwd(), 'public', relativePath)
    await writeFile(fullPath, buffer)

    // Create database record
    const evidence = await db.evidence.create({
      data: {
        tenantId: targetTenantId,
        controlId: controlId || null,
        uploadedById: user.id,
        title,
        description: description || null,
        type: 'file',
        fileName: file.name,
        filePath: `/${relativePath}`,
        fileSize: file.size,
        mimeType: file.type || null,
        tags: tags || null,
        status: 'active',
      },
      include: {
        control: { select: { id: true, ref: true, title: true, framework: { select: { code: true, name: true } } } },
        uploadedBy: { select: { id: true, name: true, email: true } },
      },
    })

    // Audit log
    await db.auditLog.create({
      data: {
        userId: user.id,
        tenantId: targetTenantId,
        action: 'evidence.upload',
        entity: 'evidence',
        entityId: evidence.id,
        meta: JSON.stringify({ title, fileName: file.name, fileSize: file.size, mimeType: file.type }),
      },
    })

    return NextResponse.json({ evidence })
  } catch (error: any) {
    console.error('Evidence upload error:', error)
    return NextResponse.json(
      { error: error.message || 'Upload failed' },
      { status: 500 }
    )
  }
}