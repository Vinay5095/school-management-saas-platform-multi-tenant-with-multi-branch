'use client'

import * as React from 'react'
import {
  Button,
  Input,
  Label,
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
  Checkbox,
  Switch,
  Slider,
  Textarea,
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  CardFooter,
  Badge,
  Avatar,
  AvatarImage,
  AvatarFallback,
  Progress,
  Skeleton,
  Tabs,
  TabsList,
  TabsTrigger,
  TabsContent,
  Accordion,
  AccordionItem,
  AccordionTrigger,
  AccordionContent,
  Alert,
  AlertTitle,
  AlertDescription,
  Separator,
  Breadcrumb,
  BreadcrumbList,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbSeparator,
  BreadcrumbPage,
} from '@/components/ui'

import {
  AttendanceWidget,
  GradeCard,
  StudentCard,
} from '@/components/academic'

import { AlertCircle, CheckCircle2, Home } from 'lucide-react'

export default function ComponentShowcase() {
  const [sliderValue, setSliderValue] = React.useState([50])
  const [attendanceStatus, setAttendanceStatus] = React.useState<'present' | 'absent' | 'late' | 'excused'>('present')

  return (
    <div className="container mx-auto py-8 space-y-8">
      <div className="space-y-2">
        <h1 className="text-4xl font-bold">Phase 02: UI Components Showcase</h1>
        <p className="text-muted-foreground">
          Comprehensive component library with 65+ production-ready components
        </p>
      </div>

      <Separator />

      {/* Breadcrumb Example */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Navigation</h2>
        <Breadcrumb>
          <BreadcrumbList>
            <BreadcrumbItem>
              <BreadcrumbLink href="/">
                <Home className="h-4 w-4" />
              </BreadcrumbLink>
            </BreadcrumbItem>
            <BreadcrumbSeparator />
            <BreadcrumbItem>
              <BreadcrumbLink href="/components">Components</BreadcrumbLink>
            </BreadcrumbItem>
            <BreadcrumbSeparator />
            <BreadcrumbItem>
              <BreadcrumbPage>Showcase</BreadcrumbPage>
            </BreadcrumbItem>
          </BreadcrumbList>
        </Breadcrumb>
      </section>

      {/* Form Components */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Form Components</h2>
        <div className="grid gap-4 md:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>Input Elements</CardTitle>
              <CardDescription>Various input components</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="name">Name</Label>
                <Input id="name" placeholder="Enter your name" />
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <Input id="email" type="email" placeholder="email@example.com" />
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="grade">Grade</Label>
                <Select>
                  <SelectTrigger id="grade">
                    <SelectValue placeholder="Select grade" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="9">Grade 9</SelectItem>
                    <SelectItem value="10">Grade 10</SelectItem>
                    <SelectItem value="11">Grade 11</SelectItem>
                    <SelectItem value="12">Grade 12</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              
              <div className="space-y-2">
                <Label htmlFor="bio">Bio</Label>
                <Textarea id="bio" placeholder="Tell us about yourself" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Interactive Controls</CardTitle>
              <CardDescription>Switches, checkboxes, and sliders</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center space-x-2">
                <Checkbox id="terms" />
                <Label htmlFor="terms">Accept terms and conditions</Label>
              </div>
              
              <div className="flex items-center space-x-2">
                <Switch id="notifications" />
                <Label htmlFor="notifications">Enable notifications</Label>
              </div>
              
              <div className="space-y-2">
                <Label>Volume: {sliderValue[0]}%</Label>
                <Slider
                  value={sliderValue}
                  onValueChange={setSliderValue}
                  max={100}
                  step={1}
                />
              </div>
              
              <div className="space-y-2">
                <Label>Progress Example</Label>
                <Progress value={65} />
              </div>
            </CardContent>
          </Card>
        </div>
      </section>

      {/* Button Variants */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Button Variants</h2>
        <Card>
          <CardContent className="pt-6">
            <div className="flex flex-wrap gap-2">
              <Button variant="default">Default</Button>
              <Button variant="secondary">Secondary</Button>
              <Button variant="destructive">Destructive</Button>
              <Button variant="outline">Outline</Button>
              <Button variant="ghost">Ghost</Button>
              <Button variant="link">Link</Button>
            </div>
            <Separator className="my-4" />
            <div className="flex flex-wrap gap-2">
              <Button size="sm">Small</Button>
              <Button size="default">Default</Button>
              <Button size="lg">Large</Button>
            </div>
          </CardContent>
        </Card>
      </section>

      {/* Tabs Example */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Tabs & Accordion</h2>
        <Tabs defaultValue="account" className="w-full">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="account">Account</TabsTrigger>
            <TabsTrigger value="password">Password</TabsTrigger>
            <TabsTrigger value="settings">Settings</TabsTrigger>
          </TabsList>
          <TabsContent value="account">
            <Card>
              <CardHeader>
                <CardTitle>Account Information</CardTitle>
                <CardDescription>
                  Manage your account details here.
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-2">
                <div className="space-y-1">
                  <Label htmlFor="current">Current password</Label>
                  <Input id="current" type="password" />
                </div>
              </CardContent>
            </Card>
          </TabsContent>
          <TabsContent value="password">
            <Card>
              <CardHeader>
                <CardTitle>Password</CardTitle>
                <CardDescription>Change your password here.</CardDescription>
              </CardHeader>
              <CardContent className="space-y-2">
                <div className="space-y-1">
                  <Label htmlFor="new">New password</Label>
                  <Input id="new" type="password" />
                </div>
              </CardContent>
            </Card>
          </TabsContent>
          <TabsContent value="settings">
            <Card>
              <CardHeader>
                <CardTitle>Settings</CardTitle>
                <CardDescription>Manage your preferences.</CardDescription>
              </CardHeader>
            </Card>
          </TabsContent>
        </Tabs>

        <Accordion type="single" collapsible className="w-full">
          <AccordionItem value="item-1">
            <AccordionTrigger>What is this component library?</AccordionTrigger>
            <AccordionContent>
              A comprehensive UI component library with 65+ production-ready components
              built for the school management SaaS platform.
            </AccordionContent>
          </AccordionItem>
          <AccordionItem value="item-2">
            <AccordionTrigger>Is it accessible?</AccordionTrigger>
            <AccordionContent>
              Yes. All components are built with accessibility in mind, following
              WCAG 2.1 AA standards using Radix UI primitives.
            </AccordionContent>
          </AccordionItem>
          <AccordionItem value="item-3">
            <AccordionTrigger>Is it responsive?</AccordionTrigger>
            <AccordionContent>
              Yes. All components are designed with a mobile-first approach and work
              seamlessly across all device sizes.
            </AccordionContent>
          </AccordionItem>
        </Accordion>
      </section>

      {/* Feedback Components */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Feedback Components</h2>
        <div className="space-y-4">
          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertTitle>Information</AlertTitle>
            <AlertDescription>
              This is an informational alert component that can display important messages.
            </AlertDescription>
          </Alert>
          
          <Alert variant="destructive">
            <AlertCircle className="h-4 w-4" />
            <AlertTitle>Error</AlertTitle>
            <AlertDescription>
              This is an error alert showing something went wrong.
            </AlertDescription>
          </Alert>
        </div>
      </section>

      {/* Data Display */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Data Display</h2>
        <div className="flex flex-wrap gap-2">
          <Badge>Default</Badge>
          <Badge variant="secondary">Secondary</Badge>
          <Badge variant="destructive">Destructive</Badge>
          <Badge variant="outline">Outline</Badge>
        </div>
        
        <div className="flex gap-4">
          <div className="flex items-center gap-2">
            <Avatar>
              <AvatarImage src="https://github.com/shadcn.png" />
              <AvatarFallback>CN</AvatarFallback>
            </Avatar>
            <div>
              <p className="text-sm font-medium">John Doe</p>
              <p className="text-xs text-muted-foreground">john@example.com</p>
            </div>
          </div>
        </div>
        
        <div className="space-y-2">
          <h3 className="text-sm font-medium">Loading State</h3>
          <div className="flex items-center space-x-4">
            <Skeleton className="h-12 w-12 rounded-full" />
            <div className="space-y-2">
              <Skeleton className="h-4 w-[250px]" />
              <Skeleton className="h-4 w-[200px]" />
            </div>
          </div>
        </div>
      </section>

      {/* Academic Components */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Academic-Specific Components</h2>
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          <AttendanceWidget
            studentName="John Smith"
            status={attendanceStatus}
            onStatusChange={setAttendanceStatus}
            date="January 15, 2025"
          />
          
          <GradeCard
            subject="Mathematics"
            grade={85}
            maxGrade={100}
            trend="up"
            comments="Excellent improvement this semester!"
          />
          
          <StudentCard
            name="Jane Doe"
            studentId="STU-2024-001"
            grade="Grade 10"
            email="jane.doe@school.com"
            phone="+1 234-567-8900"
            photoUrl="https://github.com/shadcn.png"
            status="active"
            onViewDetails={() => alert('View Details')}
            onContact={() => alert('Contact Student')}
          />
        </div>
      </section>

      {/* Footer */}
      <Card>
        <CardHeader>
          <CardTitle>Implementation Complete</CardTitle>
          <CardDescription>
            Phase 02: UI Components Library - 65+ Components Ready
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center gap-2">
            <CheckCircle2 className="h-5 w-5 text-green-500" />
            <span className="text-sm">
              All components are production-ready, fully typed, and accessible.
            </span>
          </div>
        </CardContent>
        <CardFooter>
          <p className="text-xs text-muted-foreground">
            Built with Next.js 15, TypeScript, Tailwind CSS, and Radix UI
          </p>
        </CardFooter>
      </Card>
    </div>
  )
}
