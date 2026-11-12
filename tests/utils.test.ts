import { describe,it,expect } from 'vitest';
import { initials,cn } from '../lib/utils';
describe('utility functions',()=>{it('creates initials from a full name',()=>expect(initials('Ahmad Pratama')).toBe('AP'));it('joins conditional class names',()=>expect(cn('panel',false,'active')).toBe('panel active'));});
