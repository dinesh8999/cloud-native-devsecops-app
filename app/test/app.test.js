const request = require('supertest');
const app = require('../src/app');

describe('DevSecOps API Endpoints', () => {

  describe('GET /', () => {
    it('should return 200 OK and valid project metadata', async () => {
      const response = await request(app).get('/');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('project');
      expect(response.body.project).toBe('Cloud-Native DevSecOps Pipeline on AWS');
      expect(response.body).toHaveProperty('status', 'online');
      expect(response.body).toHaveProperty('securityFeatures');
      expect(Array.isArray(response.body.securityFeatures)).toBe(true);
    });
  });

  describe('GET /health', () => {
    it('should return 200 OK with status healthy for ALB target checks', async () => {
      const response = await request(app).get('/health');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('uptime');
    });
  });

  describe('GET /version', () => {
    it('should return 200 OK with version details', async () => {
      const response = await request(app).get('/version');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('version');
      expect(response.body).toHaveProperty('gitCommit');
      expect(response.body).toHaveProperty('environment');
    });
  });

  describe('Non-existent route', () => {
    it('should return 404 for unknown endpoints', async () => {
      const response = await request(app).get('/non-existent');
      expect(response.status).toBe(404);
    });
  });

});
