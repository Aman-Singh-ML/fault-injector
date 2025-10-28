import { NextRequest, NextResponse } from 'next/server';

const GATEWAY_URL = process.env.GATEWAY_URL || 'http://localhost:9000';
const REQUEST_TIMEOUT = 30000; // 30 seconds

/**
 * Production-ready API proxy with comprehensive error handling
 */

// Helper function to build headers
function buildHeaders(request: NextRequest): Headers {
  const headers = new Headers();

  // Copy authorization header if present
  const authHeader = request.headers.get('authorization');
  if (authHeader) {
    headers.set('authorization', authHeader);
  }

  headers.set('Content-Type', 'application/json');
  return headers;
}

// Helper function to handle fetch with timeout
async function fetchWithTimeout(url: string, options: RequestInit, timeout: number = REQUEST_TIMEOUT) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeout);

  try {
    return await fetch(url, {
      ...options,
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeoutId);
  }
}

// Helper function to safely parse response
async function parseResponse(response: Response) {
  const contentType = response.headers.get('content-type');

  if (contentType?.includes('application/json')) {
    try {
      return await response.json();
    } catch (error) {
      console.error('Failed to parse JSON response:', error);
      return { error: 'Invalid JSON response from gateway' };
    }
  }

  return await response.text();
}

export async function GET(
  request: NextRequest,
  { params }: { params: { path: string[] } }
) {
  try {
    const pathSegments = params.path || [];
    const queryString = request.nextUrl.search;
    const url = `${GATEWAY_URL}/${pathSegments.join('/')}${queryString}`;

    const headers = buildHeaders(request);
    const response = await fetchWithTimeout(url, { method: 'GET', headers });
    const data = await parseResponse(response);

    return NextResponse.json(data, { status: response.status });
  } catch (error: any) {
    console.error('API proxy GET error:', error);

    if (error.name === 'AbortError') {
      return NextResponse.json(
        { error: 'Request timeout - gateway not responding' },
        { status: 504 }
      );
    }

    return NextResponse.json(
      { error: 'Failed to fetch from gateway', details: error.message },
      { status: 500 }
    );
  }
}

export async function POST(
  request: NextRequest,
  { params }: { params: { path: string[] } }
) {
  try {
    const pathSegments = params.path || [];
    const queryString = request.nextUrl.search;
    const url = `${GATEWAY_URL}/${pathSegments.join('/')}${queryString}`;

    let body;
    try {
      body = await request.json();
    } catch (error) {
      return NextResponse.json(
        { error: 'Invalid request body' },
        { status: 400 }
      );
    }

    const headers = buildHeaders(request);
    const response = await fetchWithTimeout(url, {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
    });

    const data = await parseResponse(response);
    return NextResponse.json(data, { status: response.status });
  } catch (error: any) {
    console.error('API proxy POST error:', error);

    if (error.name === 'AbortError') {
      return NextResponse.json(
        { error: 'Request timeout - gateway not responding' },
        { status: 504 }
      );
    }

    return NextResponse.json(
      { error: 'Failed to fetch from gateway', details: error.message },
      { status: 500 }
    );
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { path: string[] } }
) {
  try {
    const pathSegments = params.path || [];
    const queryString = request.nextUrl.search;
    const url = `${GATEWAY_URL}/${pathSegments.join('/')}${queryString}`;

    let body;
    try {
      body = await request.json();
    } catch (error) {
      return NextResponse.json(
        { error: 'Invalid request body' },
        { status: 400 }
      );
    }

    const headers = buildHeaders(request);
    const response = await fetchWithTimeout(url, {
      method: 'PUT',
      headers,
      body: JSON.stringify(body),
    });

    const data = await parseResponse(response);
    return NextResponse.json(data, { status: response.status });
  } catch (error: any) {
    console.error('API proxy PUT error:', error);

    if (error.name === 'AbortError') {
      return NextResponse.json(
        { error: 'Request timeout - gateway not responding' },
        { status: 504 }
      );
    }

    return NextResponse.json(
      { error: 'Failed to fetch from gateway', details: error.message },
      { status: 500 }
    );
  }
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { path: string[] } }
) {
  try {
    const pathSegments = params.path || [];
    const queryString = request.nextUrl.search;
    const url = `${GATEWAY_URL}/${pathSegments.join('/')}${queryString}`;

    const headers = buildHeaders(request);
    const response = await fetchWithTimeout(url, {
      method: 'DELETE',
      headers,
    });

    const data = await parseResponse(response);
    return NextResponse.json(data, { status: response.status });
  } catch (error: any) {
    console.error('API proxy DELETE error:', error);

    if (error.name === 'AbortError') {
      return NextResponse.json(
        { error: 'Request timeout - gateway not responding' },
        { status: 504 }
      );
    }

    return NextResponse.json(
      { error: 'Failed to fetch from gateway', details: error.message },
      { status: 500 }
    );
  }
}

